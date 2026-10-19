# Learning notes: Supabase Auth, triggers and RLS

Notes for issue #1, in my own words, so I can explain them in an interview.
Everything here is used in ScanDesk: `supabase/migrations/0001_create_profiles.sql`
and `lib/features/auth/`.

## 1. Supabase Auth

- Supabase keeps users in a private table, `auth.users`. My app never reads it
  directly. It talks to it through `supabase.auth` (`signUp`, `signInWithPassword`,
  `signOut`, `resetPasswordForEmail`, `updateUser`).
- After login, Supabase gives the app a **session**: a short-lived access token
  (a JWT) plus a refresh token. `supabase_flutter` saves the session on the device
  and refreshes it, which is why reopening the app keeps me logged in
  (`AuthCubit.checkSession`).
- `auth.users` has no `role` or `full_name` that I control, and I should not edit
  it. So app data lives in my own table, `public.profiles`, linked by the same `id`.
- The app only ever holds the **anon/publishable key**. It is safe to ship because
  it can only do what Row Level Security allows. The `service_role` key bypasses
  RLS and must never be in the app or in Git.

## 2. Why a `profiles` table

- One row per user: `id` (= `auth.users.id`), `full_name`, `role`, `site_id`.
- `id` is a foreign key to `auth.users(id) on delete cascade`: delete the user and
  the profile disappears too.
- `role` has a `check` constraint (`employee`, `technician`, `manager`), so the
  database itself rejects any other value. The app also maps unknown values to
  `employee` (`UserRole.fromValue`), the role with the least power.

## 3. Triggers

- A **trigger** is a function Postgres runs automatically when something happens
  to a table.
- `on_auth_user_created` runs `handle_new_user()` **after an insert on
  `auth.users`**. It inserts a matching row in `profiles`, copying `full_name` from
  the sign-up metadata (`data: {'full_name': ...}` in `signUp`).
- Why a trigger and not "the app inserts the profile after sign-up"? Because the
  app could crash or lose connection between the two steps and leave a user with no
  profile. The trigger runs inside the same database transaction, so it can't be
  skipped.
- A second trigger, `profiles_set_updated_at`, keeps `updated_at` correct on every
  update.

## 4. Row Level Security (RLS)

- RLS makes Postgres filter rows **per request**, based on who is asking
  (`auth.uid()` is the id from the JWT). It is enabled with
  `alter table ... enable row level security`. With RLS on and no policy, nobody
  can read or write anything.
- My policies:
  - **select**: you can read your own row, and managers can read all rows
    (`id = auth.uid() or my_role() = 'manager'`).
  - **update**: only managers can update profiles (this is how a manager promotes
    an employee).
  - There is no insert policy: only the trigger creates profiles. There is no
    delete policy: nobody deletes through the API.
- The security lives in the database, not in the UI. Even if someone calls the API
  directly and skips my app, RLS still blocks them. The app's role redirects are
  only for a good user experience.
- A blocked **update** does not raise an error. It just matches 0 rows. That is why
  `UsersRepositoryImpl.changeRole` selects the updated row back and throws
  `PermissionFailure` if nothing came back.

## 5. `security definer` and `my_role()`

- The policy needs "what is the caller's role?", which means reading `profiles`.
  But reading `profiles` triggers the policy again, so it would loop forever.
- `my_role()` is declared `security definer`: it runs with its owner's rights and
  skips RLS for that one lookup. It also sets `search_path = public` so nobody can
  trick it into calling a different function with the same name.
- `handle_new_user()` is also `security definer` because the new user has no
  permission to insert into `profiles` themselves.

## 6. How it fits the Flutter code

```
UI (LoginPage)  ->  AuthCubit  ->  AuthRepository (interface)  ->  AuthRepositoryImpl  ->  Supabase
```

- The UI never touches Supabase. The cubit holds the state
  (`AuthInitial`, `Authenticated`, `Unauthenticated`, ...). The router listens to
  the cubit and redirects: logged out -> login, logged in -> the home for my role.
- Repositories turn Supabase errors into `Failure`s so the UI can show a clear
  message.

## 7. Questions I should be able to answer

1. **Where are users stored and why do I need `profiles`?** `auth.users` is managed
   by Supabase. `profiles` holds my own fields (role, name) and is linked by `id`.
2. **Why a trigger?** It creates the profile atomically with the user, so there are
   no users without a profile.
3. **What is RLS?** Per-row access rules in Postgres, evaluated with the caller's
   identity (`auth.uid()`).
4. **Is the anon key a secret?** No, it is public by design. RLS is what protects
   the data. The `service_role` key is the secret one.
5. **Why `security definer` on `my_role()`?** To read `profiles` without the policy
   calling itself in a loop.
6. **How does the app stay logged in?** `supabase_flutter` persists and refreshes
   the session; `checkSession` restores it at startup.
7. **How do I make the first manager?** By hand in the SQL Editor, because only a
   manager can change roles:
   `update public.profiles set role = 'manager' where id = '<user id>';`
