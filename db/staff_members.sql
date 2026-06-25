create extension if not exists pgcrypto;

create sequence if not exists public.staff_number_seq;

create table if not exists public.staff_roles (
  role_name text primary key,
  created_at timestamptz not null default timezone('utc', now())
);

insert into public.staff_roles (role_name)
values
  ('Manager'),
  ('Admin'),
  ('Cashier'),
  ('Lifeguard'),
  ('Security'),
  ('Cleaning Crew'),
  ('Maintenance'),
  ('Weekend Crew')
on conflict (role_name) do nothing;

create table if not exists public.staff_members (
  id uuid primary key default gen_random_uuid(),
  staff_number bigint not null unique default nextval('public.staff_number_seq'),
  staff_code text unique,
  name text not null,
  role text not null,
  qr_payload text,
  created_at timestamptz not null default timezone('utc', now())
);

alter table public.staff_members drop column if exists category;
alter table public.staff_members drop column if exists shift;
alter table public.staff_members alter column staff_number drop default;

insert into public.staff_roles (role_name)
select distinct role
from public.staff_members
where role is not null and btrim(role) <> ''
on conflict (role_name) do nothing;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'staff_members_role_fkey'
  ) then
    alter table public.staff_members
    add constraint staff_members_role_fkey
    foreign key (role) references public.staff_roles(role_name)
    on update cascade
    on delete restrict;
  end if;
end
$$;

create or replace function public.set_staff_identity()
returns trigger
language plpgsql
as $$
begin
  if new.staff_number is null then
    perform pg_advisory_xact_lock(hashtext('public.staff_members.staff_number'));

    select coalesce(max(staff_number), 0) + 1
    into new.staff_number
    from public.staff_members;
  end if;

  if new.staff_code is null then
    new.staff_code := 'STF-' || lpad(new.staff_number::text, 3, '0');
  end if;

  return new;
end;
$$;

drop trigger if exists trg_set_staff_code on public.staff_members;
drop trigger if exists trg_set_staff_identity on public.staff_members;

create trigger trg_set_staff_identity
before insert on public.staff_members
for each row
execute function public.set_staff_identity();

alter table public.staff_members enable row level security;
alter table public.staff_roles enable row level security;

drop policy if exists "public can read staff_members" on public.staff_members;
create policy "public can read staff_members"
on public.staff_members
for select
to anon, authenticated
using (true);

drop policy if exists "public can insert staff_members" on public.staff_members;
create policy "public can insert staff_members"
on public.staff_members
for insert
to anon, authenticated
with check (true);

drop policy if exists "public can update staff_members" on public.staff_members;
create policy "public can update staff_members"
on public.staff_members
for update
to anon, authenticated
using (true)
with check (true);

drop policy if exists "public can delete staff_members" on public.staff_members;
create policy "public can delete staff_members"
on public.staff_members
for delete
to anon, authenticated
using (true);

drop policy if exists "public can read staff_roles" on public.staff_roles;
create policy "public can read staff_roles"
on public.staff_roles
for select
to anon, authenticated
using (true);

drop policy if exists "public can insert staff_roles" on public.staff_roles;
create policy "public can insert staff_roles"
on public.staff_roles
for insert
to anon, authenticated
with check (true);

drop policy if exists "public can update staff_roles" on public.staff_roles;
create policy "public can update staff_roles"
on public.staff_roles
for update
to anon, authenticated
using (true)
with check (true);

drop policy if exists "public can delete staff_roles" on public.staff_roles;
create policy "public can delete staff_roles"
on public.staff_roles
for delete
to anon, authenticated
using (true);
