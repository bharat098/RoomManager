# RoomManager — plain website

No Node, npm, Next.js, build step, or .env file is required.

## 1. Configure Supabase
Open `js/config.js` and replace `PASTE_YOUR_SUPABASE_PUBLISHABLE_KEY_HERE` with your Supabase publishable key. The project URL is already set.

Important: use only the publishable/anon key. Never put a service-role/secret key in browser code. Your Supabase Row Level Security must remain enabled.

## 2. Run locally
For a quick UI preview you can double-click `index.html`. Some browser/PWA features work better through a tiny local web server. On macOS, from this folder you can run `python3 -m http.server 8000` and open `http://localhost:8000`.

## 3. GitHub Pages
Upload these files to the root of `bharat098/RoomManager`, then GitHub → repository Settings → Pages → Deploy from a branch → `main` → `/ (root)` → Save.

The website entry file is `index.html`.

## Included
Dashboard, unified expenses, PhonePe/Cash/Card/Bank/UPI/Manual payment sources, Swiggy/Zomato/Blinkit/Zepto merchant recognition, cook attendance UI, bills with paid→expense flow, CSV/XLSX/JSON import, analytics, JSON export, responsive iPhone layout and PWA manifest/service worker.

The supplied `supabase/roommanager.sql` is retained from the previous project. The static UI can run in local-browser mode immediately. Full authenticated Supabase CRUD requires the project publishable key plus matching RLS/auth policies.
