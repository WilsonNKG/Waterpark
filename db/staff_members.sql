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
  ('Weekend Crew'),
  ('Canteen Tenant'),
  ('Stand Tenant')
on conflict (role_name) do nothing;

create table if not exists public.staff_members (
  id uuid primary key default gen_random_uuid(),
  staff_number bigint not null unique,
  staff_code text unique,
  name text not null,
  staff_type text not null default 'official_staff',
  role text not null,
  unit_number integer,
  qr_payload text,
  created_at timestamptz not null default timezone('utc', now())
);

alter table public.staff_members drop column if exists category;
alter table public.staff_members drop column if exists shift;
alter table public.staff_members add column if not exists staff_type text;
alter table public.staff_members add column if not exists unit_number integer;
alter table public.staff_members alter column staff_number drop default;

update public.staff_members
set staff_type = case
  when role in ('Penjaga Kantin', 'Canteen Tenant') then 'canteen_tenant'
  when role in ('Penjaga Stand', 'Stand Tenant') then 'stand_tenant'
  when staff_type = 'canteen_guard' then 'canteen_tenant'
  when staff_type = 'stand_guard' then 'stand_tenant'
  else 'official_staff'
end
where staff_type is null
   or staff_type in ('canteen_guard', 'stand_guard');

update public.staff_members
set role = 'Canteen Tenant'
where staff_type = 'canteen_tenant'
  and role in ('Penjaga Kantin', 'Canteen Tenant');

update public.staff_members
set role = 'Stand Tenant'
where staff_type = 'stand_tenant'
  and role in ('Penjaga Stand', 'Stand Tenant');

alter table public.staff_members
alter column staff_type set default 'official_staff';

alter table public.staff_members
alter column staff_type set not null;

update public.staff_members
set unit_number = null
where staff_type = 'official_staff';

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

alter table public.staff_members
drop constraint if exists staff_members_staff_type_check;

alter table public.staff_members
add constraint staff_members_staff_type_check
check (staff_type in ('official_staff', 'canteen_tenant', 'stand_tenant'));

alter table public.staff_members
drop constraint if exists staff_members_unit_number_check;

alter table public.staff_members
add constraint staff_members_unit_number_check
check (
  (staff_type = 'official_staff' and unit_number is null) or
  (staff_type in ('canteen_tenant', 'stand_tenant') and unit_number is not null and unit_number > 0)
) not valid;

alter table public.staff_members
drop constraint if exists staff_members_role_by_type_check;

alter table public.staff_members
add constraint staff_members_role_by_type_check
check (
  (staff_type = 'official_staff' and role not in ('Canteen Tenant', 'Stand Tenant')) or
  (staff_type = 'canteen_tenant' and role = 'Canteen Tenant') or
  (staff_type = 'stand_tenant' and role = 'Stand Tenant')
) not valid;

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
