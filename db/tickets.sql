create extension if not exists pgcrypto;

create table if not exists public.ticket_batches (
  id uuid primary key default gen_random_uuid(),
  batch_label text not null unique,
  ticket_type text not null,
  visit_date date not null,
  quantity integer not null check (quantity > 0),
  price integer not null check (price > 0),
  operator text not null,
  created_at timestamptz not null default timezone('utc', now())
);

alter table public.ticket_batches
drop constraint if exists ticket_batches_ticket_type_check;

alter table public.ticket_batches
add constraint ticket_batches_ticket_type_check
check (ticket_type in ('Weekday', 'Weekend', 'Group', 'Promo'));

create table if not exists public.tickets (
  id uuid primary key default gen_random_uuid(),
  batch_id uuid not null references public.ticket_batches(id) on delete cascade,
  ticket_number integer not null check (ticket_number > 0),
  ticket_code text not null unique,
  qr_payload text not null unique,
  status text not null default 'ready',
  printed_at timestamptz,
  scanned_at timestamptz,
  voided_at timestamptz,
  void_reason text,
  created_at timestamptz not null default timezone('utc', now()),
  unique (batch_id, ticket_number)
);

alter table public.tickets
drop constraint if exists tickets_status_check;

alter table public.tickets
add constraint tickets_status_check
check (status in ('ready', 'used', 'void'));

alter table public.tickets
drop constraint if exists tickets_void_state_check;

alter table public.tickets
add constraint tickets_void_state_check
check (
  (status = 'void' and voided_at is not null) or
  (status <> 'void')
);

create index if not exists tickets_batch_id_idx on public.tickets(batch_id);
create index if not exists tickets_status_idx on public.tickets(status);
create index if not exists tickets_scanned_at_idx on public.tickets(scanned_at);

create table if not exists public.ticket_scans (
  id uuid primary key default gen_random_uuid(),
  ticket_id uuid references public.tickets(id) on delete cascade,
  scanned_code text not null,
  scan_result text not null,
  gate_name text,
  device_name text,
  scanned_at timestamptz not null default timezone('utc', now())
);

alter table public.ticket_scans
drop constraint if exists ticket_scans_result_check;

alter table public.ticket_scans
add constraint ticket_scans_result_check
check (scan_result in ('accepted', 'already_used', 'void', 'unknown'));

create index if not exists ticket_scans_ticket_id_idx
on public.ticket_scans(ticket_id);

create index if not exists ticket_scans_scanned_at_idx
on public.ticket_scans(scanned_at desc);

create or replace function public.redeem_ticket(
  p_scanned_code text,
  p_gate_name text default null,
  p_device_name text default null
)
returns table (
  ticket_id uuid,
  batch_id uuid,
  ticket_code text,
  qr_payload text,
  status text,
  scan_result text,
  scanned_at timestamptz,
  batch_label text,
  ticket_type text,
  visit_date date
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_ticket public.tickets%rowtype;
  v_batch public.ticket_batches%rowtype;
  v_now timestamptz := timezone('utc', now());
begin
  select *
  into v_ticket
  from public.tickets as t
  where t.qr_payload = btrim(p_scanned_code)
     or t.ticket_code = btrim(p_scanned_code)
  for update;

  if not found then
    insert into public.ticket_scans (
      ticket_id,
      scanned_code,
      scan_result,
      gate_name,
      device_name,
      scanned_at
    )
    values (
      null,
      btrim(p_scanned_code),
      'unknown',
      p_gate_name,
      p_device_name,
      v_now
    );

    return query
    select
      null::uuid,
      null::uuid,
      null::text,
      null::text,
      null::text,
      'unknown'::text,
      v_now,
      null::text,
      null::text,
      null::date;
    return;
  end if;

  select *
  into v_batch
  from public.ticket_batches as b
  where b.id = v_ticket.batch_id;

  if v_ticket.status = 'ready' then
    update public.tickets
    set status = 'used',
        scanned_at = v_now
    where id = v_ticket.id
    returning * into v_ticket;

    insert into public.ticket_scans (
      ticket_id,
      scanned_code,
      scan_result,
      gate_name,
      device_name,
      scanned_at
    )
    values (
      v_ticket.id,
      btrim(p_scanned_code),
      'accepted',
      p_gate_name,
      p_device_name,
      v_now
    );

    return query
    select
      v_ticket.id,
      v_ticket.batch_id,
      v_ticket.ticket_code,
      v_ticket.qr_payload,
      v_ticket.status,
      'accepted'::text,
      v_ticket.scanned_at,
      v_batch.batch_label,
      v_batch.ticket_type,
      v_batch.visit_date;
    return;
  end if;

  if v_ticket.status = 'used' then
    insert into public.ticket_scans (
      ticket_id,
      scanned_code,
      scan_result,
      gate_name,
      device_name,
      scanned_at
    )
    values (
      v_ticket.id,
      btrim(p_scanned_code),
      'already_used',
      p_gate_name,
      p_device_name,
      v_now
    );

    return query
    select
      v_ticket.id,
      v_ticket.batch_id,
      v_ticket.ticket_code,
      v_ticket.qr_payload,
      v_ticket.status,
      'already_used'::text,
      v_ticket.scanned_at,
      v_batch.batch_label,
      v_batch.ticket_type,
      v_batch.visit_date;
    return;
  end if;

  insert into public.ticket_scans (
    ticket_id,
    scanned_code,
    scan_result,
    gate_name,
    device_name,
    scanned_at
  )
  values (
    v_ticket.id,
    btrim(p_scanned_code),
    'void',
    p_gate_name,
    p_device_name,
    v_now
  );

  return query
  select
    v_ticket.id,
    v_ticket.batch_id,
    v_ticket.ticket_code,
    v_ticket.qr_payload,
    v_ticket.status,
    'void'::text,
    v_ticket.scanned_at,
    v_batch.batch_label,
    v_batch.ticket_type,
    v_batch.visit_date;
end;
$$;

alter table public.ticket_batches enable row level security;
alter table public.tickets enable row level security;
alter table public.ticket_scans enable row level security;

drop policy if exists "public can read ticket_batches" on public.ticket_batches;
create policy "public can read ticket_batches"
on public.ticket_batches
for select
to anon, authenticated
using (true);

drop policy if exists "public can insert ticket_batches" on public.ticket_batches;
create policy "public can insert ticket_batches"
on public.ticket_batches
for insert
to anon, authenticated
with check (true);

drop policy if exists "public can update ticket_batches" on public.ticket_batches;
create policy "public can update ticket_batches"
on public.ticket_batches
for update
to anon, authenticated
using (true)
with check (true);

drop policy if exists "public can delete ticket_batches" on public.ticket_batches;
create policy "public can delete ticket_batches"
on public.ticket_batches
for delete
to anon, authenticated
using (true);

drop policy if exists "public can read tickets" on public.tickets;
create policy "public can read tickets"
on public.tickets
for select
to anon, authenticated
using (true);

drop policy if exists "public can insert tickets" on public.tickets;
create policy "public can insert tickets"
on public.tickets
for insert
to anon, authenticated
with check (true);

drop policy if exists "public can update tickets" on public.tickets;
create policy "public can update tickets"
on public.tickets
for update
to anon, authenticated
using (true)
with check (true);

drop policy if exists "public can delete tickets" on public.tickets;
create policy "public can delete tickets"
on public.tickets
for delete
to anon, authenticated
using (true);

drop policy if exists "public can read ticket_scans" on public.ticket_scans;
create policy "public can read ticket_scans"
on public.ticket_scans
for select
to anon, authenticated
using (true);

drop policy if exists "public can insert ticket_scans" on public.ticket_scans;
create policy "public can insert ticket_scans"
on public.ticket_scans
for insert
to anon, authenticated
with check (true);

drop policy if exists "public can update ticket_scans" on public.ticket_scans;
create policy "public can update ticket_scans"
on public.ticket_scans
for update
to anon, authenticated
using (true)
with check (true);

drop policy if exists "public can delete ticket_scans" on public.ticket_scans;
create policy "public can delete ticket_scans"
on public.ticket_scans
for delete
to anon, authenticated
using (true);

grant execute on function public.redeem_ticket(text, text, text)
to anon, authenticated;
