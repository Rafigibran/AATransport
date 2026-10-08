-- A&A Transport - application pricing settings (migration 005)
-- Run AFTER 202610080001_init_aatransport.sql and 202610080002_admin_panel.sql.
--
-- Commercial rule from 2026-10-08: tax and service fee are DISABLED by
-- default (0%). Admins can enable/adjust them from Admin Panel > Pengaturan.
-- The percentages are snapshotted onto each booking so later setting changes
-- never rewrite the meaning of an existing e-receipt.

create table if not exists public.app_settings (
  id integer primary key check (id = 1),
  tax_percent numeric(5,2) not null default 0 check (tax_percent between 0 and 100),
  fee_percent numeric(5,2) not null default 0 check (fee_percent between 0 and 100),
  updated_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default now()
);

insert into public.app_settings (id, tax_percent, fee_percent)
values (1, 0, 0)
on conflict (id) do nothing;

alter table public.app_settings enable row level security;

drop policy if exists "app_settings_public_read" on public.app_settings;
create policy "app_settings_public_read" on public.app_settings
  for select using (true);

drop policy if exists "app_settings_admin_write" on public.app_settings;
create policy "app_settings_admin_write" on public.app_settings
  for all using (public.is_admin()) with check (public.is_admin());

-- Historical bookings need explicit columns so the receipt can show what was
-- actually charged. Defaults are 0; old totals remain stored as-is.
alter table public.bookings
  add column if not exists fee integer not null default 0 check (fee >= 0),
  add column if not exists tax_percent numeric(5,2) not null default 0 check (tax_percent between 0 and 100),
  add column if not exists fee_percent numeric(5,2) not null default 0 check (fee_percent between 0 and 100);
