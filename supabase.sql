create table if not exists public.team_sheet (
  id boolean primary key default true check (id),
  version bigint not null default 0,
  payload jsonb
);

insert into public.team_sheet (id, version, payload)
values (true, 0, null)
on conflict (id) do nothing;

create table if not exists public.user_matches (
  user_id uuid primary key references auth.users(id) on delete cascade,
  version bigint not null default 0,
  payload jsonb not null
);

insert into public.user_matches (user_id, version, payload)
select users.id, 1, team_sheet.payload->'match'
from auth.users as users
cross join public.team_sheet as team_sheet
where team_sheet.id = true
  and team_sheet.payload ? 'match'
  and jsonb_typeof(team_sheet.payload->'match') = 'object'
on conflict (user_id) do nothing;

update public.team_sheet
set payload = payload - 'match', version = version + 1
where id = true and payload ? 'match';

alter table public.team_sheet enable row level security;

drop policy if exists "Authenticated users can read team sheet" on public.team_sheet;
create policy "Authenticated users can read team sheet"
  on public.team_sheet for select to authenticated using (true);

revoke all on public.team_sheet from anon, authenticated;
grant select on public.team_sheet to authenticated;

create or replace function public.save_team_sheet(p_expected_version bigint, p_payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  saved public.team_sheet;
begin
  if p_payload is null or jsonb_typeof(p_payload) <> 'object' then
    raise exception 'Payload must be a JSON object';
  end if;

  update public.team_sheet
  set payload = p_payload - 'match', version = version + 1
  where id = true and version = p_expected_version
  returning * into saved;

  if not found then
    return null;
  end if;

  return jsonb_build_object('version', saved.version, 'payload', saved.payload);
end;
$$;

revoke all on function public.save_team_sheet(bigint, jsonb) from public, anon;
grant execute on function public.save_team_sheet(bigint, jsonb) to authenticated;

alter table public.user_matches enable row level security;

drop policy if exists "Users can read their own match" on public.user_matches;
create policy "Users can read their own match"
  on public.user_matches for select to authenticated
  using (user_id = (select auth.uid()));

revoke all on public.user_matches from anon, authenticated;
grant select on public.user_matches to authenticated;

create or replace function public.save_user_match(p_expected_version bigint, p_payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  saved public.user_matches;
  current_user_id uuid := auth.uid();
begin
  if current_user_id is null then
    raise exception 'Authentication required';
  end if;
  if p_payload is null or jsonb_typeof(p_payload) <> 'object' then
    raise exception 'Payload must be a JSON object';
  end if;

  if p_expected_version = 0 then
    insert into public.user_matches (user_id, version, payload)
    values (current_user_id, 1, p_payload)
    on conflict (user_id) do nothing
    returning * into saved;
  else
    update public.user_matches
    set payload = p_payload, version = version + 1
    where user_id = current_user_id and version = p_expected_version
    returning * into saved;
  end if;

  if not found then
    return null;
  end if;

  return jsonb_build_object('version', saved.version, 'payload', saved.payload);
end;
$$;

revoke all on function public.save_user_match(bigint, jsonb) from public, anon;
grant execute on function public.save_user_match(bigint, jsonb) to authenticated;

-- Sessioni attive per utente (presenza e chiusura forzata delle altre sessioni)
create table if not exists public.user_sessions (
  user_id uuid not null references auth.users(id) on delete cascade,
  session_id text not null,
  device text,
  last_seen timestamptz not null default now(),
  revoked boolean not null default false,
  primary key (user_id, session_id)
);

alter table public.user_sessions enable row level security;
revoke all on public.user_sessions from anon, authenticated;

create or replace function public.heartbeat_user_session(p_session_id text, p_device text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  is_revoked boolean;
begin
  if uid is null then
    raise exception 'Authentication required';
  end if;

  delete from public.user_sessions
  where user_id = uid and last_seen < now() - interval '1 day';

  select revoked into is_revoked
  from public.user_sessions where user_id = uid and session_id = p_session_id;

  if coalesce(is_revoked, false) then
    return jsonb_build_object('revoked', true);
  end if;

  insert into public.user_sessions (user_id, session_id, device, last_seen)
  values (uid, p_session_id, left(p_device, 80), now())
  on conflict (user_id, session_id)
  do update set last_seen = now(), device = excluded.device;

  return jsonb_build_object(
    'revoked', false,
    'others', coalesce((
      select jsonb_agg(jsonb_build_object('device', device, 'last_seen', last_seen))
      from public.user_sessions
      where user_id = uid and session_id <> p_session_id
        and not revoked and last_seen > now() - interval '90 seconds'
    ), '[]'::jsonb)
  );
end;
$$;

create or replace function public.kick_other_sessions(p_session_id text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;
  update public.user_sessions set revoked = true
  where user_id = auth.uid() and session_id <> p_session_id;
end;
$$;

create or replace function public.end_user_session(p_session_id text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;
  delete from public.user_sessions
  where user_id = auth.uid() and session_id = p_session_id;
end;
$$;

revoke all on function public.heartbeat_user_session(text, text) from public, anon;
revoke all on function public.kick_other_sessions(text) from public, anon;
revoke all on function public.end_user_session(text) from public, anon;
grant execute on function public.heartbeat_user_session(text, text) to authenticated;
grant execute on function public.kick_other_sessions(text) to authenticated;
grant execute on function public.end_user_session(text) to authenticated;
