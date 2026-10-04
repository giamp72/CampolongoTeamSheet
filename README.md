# CampolongoTeamSheet

Static webpage for the Campolongo team sheet, hosted on GitHub Pages. Shared data synchronization uses Supabase.

## Configure shared data

1. Create a Supabase project and create one Auth user per person in **Authentication → Users**. Keep public sign-ups disabled.
2. In the Supabase SQL Editor, run [`supabase.sql`](supabase.sql). It creates the shared record and a version-checked write function. A stale write is rejected rather than overwriting another user's changes.
3. In `index.html`, set `SUPABASE_URL` and `SUPABASE_ANON_KEY` to the project's Project URL and publishable/anon key. These values are intended to be public; **never put a `service_role` key in the page**.
4. Publish the repository with GitHub Pages. Each user signs in with their own account. Changes to the team, match, roster, and staff are synchronized to the shared record.

On the first sign-in, the existing browser data initializes the shared record. Later sessions load the shared record. If two users change it concurrently, the stale write is refused and the user's local changes are kept; the user can then explicitly reload the shared version. Data is also cached in that browser's local storage, but GitHub Pages cannot write a JSON backup file beside `index.html`.

If Supabase is not configured, the app remains in local-only mode.
