-- 1) Create an admin user in Supabase Dashboard first:
-- Authentication -> Users -> Add user -> create an Email/Password user.
-- Copy that user's UUID and replace YOUR_ADMIN_USER_UUID below.

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

alter table public.admin_users enable row level security;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.admin_users
    where user_id = auth.uid()
  );
$$;

grant execute on function public.is_admin() to authenticated;

-- Add your Supabase Auth user's UUID here.
insert into public.admin_users (user_id)
values ('YOUR_ADMIN_USER_UUID')
on conflict (user_id) do nothing;

-- Admins can read all clinics and all patient records.
-- Clinic-facing RPC functions continue to control clinic access.

drop policy if exists "Admins can read clinics" on public.clinics;
create policy "Admins can read clinics"
on public.clinics
for select
to authenticated
using (public.is_admin());

drop policy if exists "Admins can read patients" on public.patients;
create policy "Admins can read patients"
on public.patients
for select
to authenticated
using (public.is_admin());
