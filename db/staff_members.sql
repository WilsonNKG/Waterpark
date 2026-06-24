create extension if not exists pgcrypto;

create sequence if not exists public.staff_number_seq;

create table if not exists public.staff_members (
  id uuid primary key default gen_random_uuid(),
  staff_number bigint not null unique default nextval('public.staff_number_seq'),
  staff_code text unique,
  name text not null,
  role text not null,
  qr_payload text,
  created_at timestamptz not null default timezone('utc', now())
);

create or replace function public.set_staff_code()
returns trigger
language plpgsql
as $$
begin
  if new.staff_code is null then
    new.staff_code := 'STF-' || lpad(new.staff_number::text, 3, '0');
  end if;
  return new;
end;
$$;

drop trigger if exists trg_set_staff_code on public.staff_members;

create trigger trg_set_staff_code
before insert on public.staff_members
for each row
execute function public.set_staff_code();

alter table public.staff_members enable row level security;

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
