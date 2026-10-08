-- A&A Transport - Admin Panel support
-- Run AFTER 202610080001_init_aatransport.sql in Supabase SQL Editor.

-- ---------- role ----------
alter table public.profiles
  add column if not exists role text not null default 'user'
  check (role in ('user','admin'));

create or replace function public.is_admin()
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  );
$$;

-- Make your first admin after that account has registered/logged in once:
-- update public.profiles set role = 'admin' where email = 'email-admin-kamu@contoh.com';

-- ---------- admin log ----------
create table if not exists public.admin_logs (
  id uuid primary key default gen_random_uuid(),
  admin_id uuid not null references public.profiles(id) on delete cascade,
  action text not null,
  entity text not null,
  entity_id text,
  detail jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

alter table public.admin_logs enable row level security;

drop policy if exists "admin_logs_admin_all" on public.admin_logs;
create policy "admin_logs_admin_all" on public.admin_logs
  for all using (public.is_admin()) with check (public.is_admin() and auth.uid() = admin_id);

-- ---------- profiles: admin can manage customers ----------
drop policy if exists "profiles_admin_select" on public.profiles;
create policy "profiles_admin_select" on public.profiles for select using (public.is_admin());
drop policy if exists "profiles_admin_update" on public.profiles;
create policy "profiles_admin_update" on public.profiles for update using (public.is_admin()) with check (public.is_admin());

-- ---------- cars catalogue: admin write ----------
drop policy if exists "cars_admin_write" on public.cars;
create policy "cars_admin_write" on public.cars
  for all using (public.is_admin()) with check (public.is_admin());

drop policy if exists "car_photos_admin_write" on public.car_photos;
create policy "car_photos_admin_write" on public.car_photos
  for all using (public.is_admin()) with check (public.is_admin());

drop policy if exists "features_admin_write" on public.features;
create policy "features_admin_write" on public.features
  for all using (public.is_admin()) with check (public.is_admin());

drop policy if exists "car_features_admin_write" on public.car_features;
create policy "car_features_admin_write" on public.car_features
  for all using (public.is_admin()) with check (public.is_admin());

-- ---------- bookings/payments/reviews: admin access ----------
drop policy if exists "bookings_admin_select" on public.bookings;
create policy "bookings_admin_select" on public.bookings for select using (public.is_admin());
drop policy if exists "bookings_admin_update" on public.bookings;
create policy "bookings_admin_update" on public.bookings for update using (public.is_admin()) with check (public.is_admin());

drop policy if exists "payments_admin_select" on public.payments;
create policy "payments_admin_select" on public.payments for select using (public.is_admin());
drop policy if exists "payments_admin_update" on public.payments;
create policy "payments_admin_update" on public.payments for update using (public.is_admin()) with check (public.is_admin());

drop policy if exists "reviews_admin_delete" on public.reviews;
create policy "reviews_admin_delete" on public.reviews for delete using (public.is_admin());
drop policy if exists "favourites_admin_select" on public.favourites;
create policy "favourites_admin_select" on public.favourites for select using (public.is_admin());

-- ---------- storage: admin can manage car images ----------
drop policy if exists "car_images_admin_write" on storage.objects;
create policy "car_images_admin_write" on storage.objects
  for all using (bucket_id = 'car-images' and public.is_admin())
  with check (bucket_id = 'car-images' and public.is_admin());
