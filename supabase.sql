create table if not exists public.team_sheet (
  id boolean primary key default true check (id),
  version bigint not null default 0,
  payload jsonb
);

insert into public.team_sheet (id, version, payload)
values (true, 0, null)
on conflict (id) do nothing;

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
  if jsonb_typeof(p_payload) <> 'object' then
    raise exception 'Payload must be a JSON object';
  end if;

  update public.team_sheet
  set payload = p_payload, version = version + 1
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
