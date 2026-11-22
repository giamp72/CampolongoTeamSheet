# CampolongoTeamSheet

Static webpage for the Campolongo team sheet, hosted on GitHub Pages. Shared data synchronization uses Supabase.

## Configure shared data

1. Create a Supabase project and one Auth user per person in **Authentication → Users**. Keep public sign-ups disabled.
2. In the Supabase SQL Editor, run [`supabase.sql`](supabase.sql). If `team_sheet` already exists, run the updated script again: it copies the current shared match into each existing user's private match and removes it from the shared record. Existing private matches are preserved on later runs.
3. In `index.html`, set `SUPABASE_URL` and `SUPABASE_ANON_KEY` to the project's Project URL and publishable/anon key. These values are intended to be public; **never put a `service_role` key in the page**.
4. Publish the repository with GitHub Pages. Each user signs in with their own account. The roster, staff, and team details are shared; match details, player selections, and staff assignments are private to the signed-in user.

The first signed-in user can initialize an empty shared roster record from that browser. Existing users receive a copy of the previously shared match as the starting point for their own private match. Later sessions load each user's match from Supabase. If two users edit the shared roster concurrently, or one user's match from multiple devices, a stale write is refused and local changes are retained. Data is also cached in that browser's local storage, but GitHub Pages cannot write a JSON backup file beside `index.html`.

If Supabase is not configured, the app remains in local-only mode.

## Sessioni multiple dello stesso account

Se lo stesso account è aperto su più dispositivi, solo la prima sessione aperta può modificare i dati; le altre sono in **sola lettura** (consultazione, filtri, stampe e lista WhatsApp restano disponibili) e si aggiornano automaticamente ogni 30 secondi. Il ruolo di modifica passa a un'altra sessione quando la prima esce, resta inattiva per 90 secondi oppure quando da un'altra sessione si preme **Modifica da questo dispositivo**, che disconnette le altre. Account diversi non si bloccano a vicenda.

Dopo l'aggiornamento dell'app eseguire di nuovo [`supabase.sql`](supabase.sql) nel SQL Editor: aggiunge la colonna `is_editor` a `user_sessions` e aggiorna le funzioni delle sessioni. Lo script è ripetibile e non modifica rosa e convocazioni. Finché il database non è aggiornato, tutte le sessioni restano modificabili come prima.

Senza connessione l'app resta utilizzabile con i dati locali e non chiede un nuovo accesso: la sincronizzazione riprende quando torna la rete.

## Test

```
npm test
```

## Install as an app

On Android, open the published site in Chrome and choose **Install app** (or **Add to Home screen**) from the browser menu. The app shell and images are cached for offline opening; signing in and synchronizing with Supabase still require an internet connection. Printing uses the browser's print dialog: choose **Save as PDF** on Android.

## Certificati medici

Nella rosa inserire la scadenza del certificato medico di ciascun giocatore, separatamente dalla data di rilascio del documento. Le scadenze sono condivise insieme alla rosa e incluse nei backup dei dati. I nomi sono evidenziati in arancione nella rosa e nella convocazione quando la scadenza è compresa tra oggi e i 60 giorni successivi, estremi inclusi, e in rosso quando è già trascorsa. Le date mancanti non sono segnalate. Il pulsante **Certificati in scadenza** mostra anche i certificati scaduti, ordinati per data, e permette di stampare la lista.
