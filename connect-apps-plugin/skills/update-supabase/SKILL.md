---
description: Update the Supabase project URL and anon key in bp-app.js
---

The user wants to update the Supabase connection credentials in `bp-app.js`.

1. Read `bp-app.js` and locate the `_u` (project URL) and `_k` (anon key) constants near the top of the file (look for the `/* ── SUPABASE ──` section).
2. Ask the user for the new Supabase project URL and anon key if they haven't provided them.
3. The URL is split across an array joined with `""` — keep that pattern.
4. The key is split into three parts joined with `""` — keep that pattern, splitting after the first `.` and second `.` in the JWT.
5. Replace the existing values with the new ones using the Edit tool.
6. After editing, confirm the change by reading back the updated lines and reporting the new project ref extracted from the URL.
