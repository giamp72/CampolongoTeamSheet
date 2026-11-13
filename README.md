# CampolongoTeamSheet

Static webpage for the Campolongo team sheet, hosted on GitHub Pages. Shared data synchronization uses Supabase.

## Configure shared data

1. Create a Supabase project and one Auth user per person in **Authentication → Users**. Keep public sign-ups disabled.
2. In the Supabase SQL Editor, run [`supabase.sql`](supabase.sql). If `team_sheet` already exists, run the updated script again: it copies the current shared match into each existing user's private match and removes it from the shared record. Existing private matches are preserved on later runs.
3. In `index.html`, set `SUPABASE_URL` and `SUPABASE_ANON_KEY` to the project's Project URL and publishable/anon key. These values are intended to be public; **never put a `service_role` key in the page**.
4. Publish the repository with GitHub Pages. Each user signs in with their own account. The roster, staff, and team details are shared; match details, player selections, and staff assignments are private to the signed-in user.

The first signed-in user can initialize an empty shared roster record from that browser. Existing users receive a copy of the previously shared match as the starting point for their own private match. Later sessions load each user's match from Supabase. If two users edit the shared roster concurrently, or one user's match from multiple devices, a stale write is refused and local changes are retained. Data is also cached in that browser's local storage, but GitHub Pages cannot write a JSON backup file beside `index.html`.

If Supabase is not configured, the app remains in local-only mode.

## Install as an app

On Android, open the published site in Chrome and choose **Install app** (or **Add to Home screen**) from the browser menu. The app shell and images are cached for offline opening; signing in and synchronizing with Supabase still require an internet connection. Printing uses the browser's print dialog: choose **Save as PDF** on Android.

## Certificati medici

Nella rosa inserire la scadenza del certificato medico di ciascun giocatore, separatamente dalla data di rilascio del documento. Le scadenze sono condivise insieme alla rosa e incluse nei backup dei dati. I nomi sono evidenziati in arancione nella rosa e nella convocazione quando la scadenza è compresa tra oggi e i 60 giorni successivi, estremi inclusi, e in rosso quando è già trascorsa. Le date mancanti non sono segnalate. Il pulsante **Certificati in scadenza** mostra anche i certificati scaduti, ordinati per data, e permette di stampare la lista.
