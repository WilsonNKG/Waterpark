# waterpark

Flutter admin app for Puri Nirwana Waterpark.

## Staff Access

The `Staff Access` page now supports:

- loading staff records from Supabase
- creating and deleting staff
- generating, viewing, and deleting per-staff QR payloads
- local fallback sample data when Supabase keys are not configured yet

## Supabase setup

1. Create a Supabase project.
2. Open the SQL editor and run [db/staff_members.sql](/Users/wilsonmehaga/Documents/Programming%20Projects/NKG_APP/waterpark/db/staff_members.sql:1).
3. Run the app with your project values:

```bash
flutter run \
  --dart-define=SUPABASE_URL=YOUR_SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
```

If `SUPABASE_URL` and `SUPABASE_ANON_KEY` are missing, the app stays usable with local sample staff data.

## Local config file

For this workspace, you can also run with a local file that stays ignored by Git:

```bash
flutter run -d chrome --dart-define-from-file=env/supabase.local.json
```

Use [env/supabase.example.json](/Users/wilsonmehaga/Documents/Programming%20Projects/NKG_APP/waterpark/env/supabase.example.json:1) as the template. The real local file is ignored by `.gitignore`.
