-- A&A Transport - Supabase initial schema (car booking)
-- Run this file once in Supabase Dashboard > SQL Editor (or via `supabase db push`).

create extension if not exists pgcrypto;

-- ---------- helpers ----------
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- ---------- profiles ----------
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  email text not null default '',
  phone text,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, full_name, email, phone)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', ''),
    coalesce(new.email, ''),
    new.raw_user_meta_data ->> 'phone'
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------- cars ----------
create table if not exists public.cars (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  location text not null, -- pickup city / base
  description text not null default '',
  price_per_day integer not null check (price_per_day >= 0), -- IDR
  image_url text not null default '',
  car_type text not null default 'MPV',
  seats integer not null default 7,
  transmission text not null default 'Automatic',
  fuel_type text not null default 'Bensin',
  baggage integer not null default 2,
  rating numeric(3,2) not null default 0,
  review_count integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.car_photos (
  id uuid primary key default gen_random_uuid(),
  car_id uuid not null references public.cars(id) on delete cascade,
  url text not null,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.features (
  id uuid primary key default gen_random_uuid(),
  name text not null unique
);

create table if not exists public.car_features (
  car_id uuid not null references public.cars(id) on delete cascade,
  feature_id uuid not null references public.features(id) on delete cascade,
  primary key (car_id, feature_id)
);

-- ---------- favourites ----------
create table if not exists public.favourites (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  car_id uuid not null references public.cars(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (user_id, car_id)
);

-- ---------- bookings & payments ----------
create table if not exists public.bookings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  car_id uuid not null references public.cars(id) on delete restrict,
  pickup_date date not null,
  return_date date not null,
  passengers integer not null default 1 check (passengers > 0),
  units integer not null default 1 check (units > 0),
  service_type text not null default 'Dengan Sopir',
  customer_name text not null,
  customer_email text not null,
  customer_phone text not null,
  days integer not null check (days > 0),
  subtotal integer not null check (subtotal >= 0), -- IDR
  tax integer not null default 0 check (tax >= 0), -- IDR
  total integer not null check (total >= 0), -- IDR
  status text not null default 'pending_payment'
    check (status in ('pending_payment','confirmed','completed','cancelled','expired')),
  payment_method_code text,
  payment_status text not null default 'pending'
    check (payment_status in ('pending','berhasil','expired','failed')),
  merchant_ref text unique,
  sakurupiah_trx_id text,
  checkout_url text,
  payment_no text,
  qr_string text,
  payment_expired_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (return_date > pickup_date)
);

create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  provider text not null default 'sakurupiah',
  method_code text not null,
  trx_id text unique,
  merchant_ref text not null unique,
  amount integer not null check (amount >= 0),
  status text not null default 'pending'
    check (status in ('pending','berhasil','expired','failed')),
  checkout_url text,
  payment_no text,
  qr_string text,
  expired_at timestamptz,
  callback_payload jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ---------- reviews ----------
create table if not exists public.reviews (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  car_id uuid not null references public.cars(id) on delete cascade,
  booking_id uuid references public.bookings(id) on delete set null,
  rating integer not null check (rating between 1 and 5),
  comment text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (booking_id)
);

create or replace function public.refresh_car_rating()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  target_car uuid := coalesce(new.car_id, old.car_id);
begin
  update public.cars c
  set rating = coalesce((select round(avg(r.rating)::numeric, 2) from public.reviews r where r.car_id = target_car), 0),
      review_count = (select count(*) from public.reviews r where r.car_id = target_car)
  where c.id = target_car;
  return coalesce(new, old);
end;
$$;

drop trigger if exists reviews_refresh_rating on public.reviews;
create trigger reviews_refresh_rating
  after insert or update or delete on public.reviews
  for each row execute function public.refresh_car_rating();

-- ---------- saved payment methods (channel preferences only, never card secrets) ----------
create table if not exists public.saved_payment_methods (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  method_code text not null, -- e.g. QRIS, BCAVA, BRIVA, GOPAY, DANA, ShopeePay
  label text not null,
  created_at timestamptz not null default now(),
  unique (user_id, method_code)
);

-- ---------- updated_at triggers ----------
drop trigger if exists profiles_updated on public.profiles;
create trigger profiles_updated before update on public.profiles for each row execute function public.set_updated_at();
drop trigger if exists cars_updated on public.cars;
create trigger cars_updated before update on public.cars for each row execute function public.set_updated_at();
drop trigger if exists bookings_updated on public.bookings;
create trigger bookings_updated before update on public.bookings for each row execute function public.set_updated_at();
drop trigger if exists payments_updated on public.payments;
create trigger payments_updated before update on public.payments for each row execute function public.set_updated_at();
drop trigger if exists reviews_updated on public.reviews;
create trigger reviews_updated before update on public.reviews for each row execute function public.set_updated_at();

-- ---------- RLS ----------
alter table public.profiles enable row level security;
alter table public.cars enable row level security;
alter table public.car_photos enable row level security;
alter table public.features enable row level security;
alter table public.car_features enable row level security;
alter table public.favourites enable row level security;
alter table public.bookings enable row level security;
alter table public.payments enable row level security;
alter table public.reviews enable row level security;
alter table public.saved_payment_methods enable row level security;

-- profiles: own only
drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own" on public.profiles for select using (auth.uid() = id);
drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own" on public.profiles for update using (auth.uid() = id) with check (auth.uid() = id);
drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own" on public.profiles for insert with check (auth.uid() = id);

-- cars & catalogue: public read, writes only via service role (dashboard / SQL editor)
drop policy if exists "cars_public_read" on public.cars;
create policy "cars_public_read" on public.cars for select using (is_active = true);
drop policy if exists "car_photos_public_read" on public.car_photos;
create policy "car_photos_public_read" on public.car_photos for select using (true);
drop policy if exists "features_public_read" on public.features;
create policy "features_public_read" on public.features for select using (true);
drop policy if exists "car_features_public_read" on public.car_features;
create policy "car_features_public_read" on public.car_features for select using (true);

-- favourites: own
drop policy if exists "favourites_own" on public.favourites;
create policy "favourites_own" on public.favourites for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- bookings: own read/insert, own update (app only cancels; payment fields are set by Edge Functions with service role)
drop policy if exists "bookings_select_own" on public.bookings;
create policy "bookings_select_own" on public.bookings for select using (auth.uid() = user_id);
drop policy if exists "bookings_insert_own" on public.bookings;
create policy "bookings_insert_own" on public.bookings for insert with check (auth.uid() = user_id);
drop policy if exists "bookings_update_own" on public.bookings;
create policy "bookings_update_own" on public.bookings for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- payments: own read only from client; Edge Functions (service role) write
drop policy if exists "payments_select_own" on public.payments;
create policy "payments_select_own" on public.payments for select using (auth.uid() = user_id);

-- reviews: public read, own write
drop policy if exists "reviews_public_read" on public.reviews;
create policy "reviews_public_read" on public.reviews for select using (true);
drop policy if exists "reviews_insert_own" on public.reviews;
create policy "reviews_insert_own" on public.reviews for insert with check (auth.uid() = user_id);
drop policy if exists "reviews_update_own" on public.reviews;
create policy "reviews_update_own" on public.reviews for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
drop policy if exists "reviews_delete_own" on public.reviews;
create policy "reviews_delete_own" on public.reviews for delete using (auth.uid() = user_id);

-- saved payment methods: own
drop policy if exists "saved_payment_methods_own" on public.saved_payment_methods;
create policy "saved_payment_methods_own" on public.saved_payment_methods for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ---------- Storage: car images bucket (public read) ----------
insert into storage.buckets (id, name, public)
values ('car-images', 'car-images', true)
on conflict (id) do nothing;

drop policy if exists "car_images_public_read" on storage.objects;
create policy "car_images_public_read" on storage.objects for select
  using (bucket_id = 'car-images');
drop policy if exists "car_images_auth_upload" on storage.objects;
create policy "car_images_auth_upload" on storage.objects for insert
  with check (bucket_id = 'car-images' and auth.role() = 'authenticated');

-- ---------- Seed: features ----------
insert into public.features (name) values
  ('Air Conditioning'), ('Bluetooth Audio'), ('USB Charger'), ('GPS Navigation'),
  ('Child Seat'), ('Roof Rack'), ('Backup Camera'), ('Cruise Control')
on conflict (name) do nothing;

-- ---------- Seed: cars (prices in IDR per day) ----------
insert into public.cars (name, location, description, price_per_day, image_url, car_type, seats, transmission, fuel_type, baggage, rating, review_count)
values
  ('Toyota Avanza', 'Makassar', 'MPV keluarga yang irit dan nyaman untuk perjalanan dalam dan luar kota. Kabin lega, cocok untuk rombongan kecil hingga 7 penumpang.', 350000, 'https://images.unsplash.com/photo-1549317661-bd32c8ce0db2?w=900&q=80', 'MPV', 7, 'Automatic', 'Bensin', 2, 4.6, 0),
  ('Toyota Innova Zenix', 'Makassar', 'MPV premium dengan kabin senyap dan fitur keselamatan lengkap. Pilihan favorit untuk perjalanan bisnis dan keluarga.', 650000, 'https://images.unsplash.com/photo-1568605117036-5fe5e7bab0b7?w=900&q=80', 'MPV', 7, 'Automatic', 'Hybrid', 3, 4.8, 0),
  ('Toyota Hiace Premio', 'Makassar', 'Van besar 14 kursi untuk rombongan, outing kantor, dan wisata grup. Ruang kabin luas dengan AC dingin merata.', 1100000, 'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?w=900&q=80', 'Van', 14, 'Manual', 'Diesel', 6, 4.7, 0),
  ('Toyota Alphard', 'Jakarta', 'Mobil premium dengan captain seat mewah untuk tamu VIP, acara pernikahan, dan perjalanan eksekutif.', 2500000, 'https://images.unsplash.com/photo-1503376780353-3e669a7b70b9?w=900&q=80', 'Premium', 7, 'Automatic', 'Bensin', 3, 4.9, 0),
  ('Mitsubishi Pajero Sport', 'Makassar', 'SUV tangguh untuk segala medan, cocok untuk perjalanan luar kota dan proyek lapangan.', 950000, 'https://images.unsplash.com/photo-1519641471654-76ce0107ad1b?w=900&q=80', 'SUV', 7, 'Automatic', 'Diesel', 3, 4.5, 0),
  ('Toyota Fortuner', 'Surabaya', 'SUV gagah dengan ground clearance tinggi dan kabin nyaman untuk perjalanan jauh bersama keluarga.', 900000, 'https://images.unsplash.com/photo-1533473359331-0135ef1b58bf?w=900&q=80', 'SUV', 7, 'Automatic', 'Diesel', 3, 4.6, 0)
on conflict do nothing;

-- photos
insert into public.car_photos (car_id, url, sort_order)
select c.id, p.url, p.ord
from public.cars c
join (values
  ('Toyota Avanza', 'https://images.unsplash.com/photo-1549317661-bd32c8ce0db2?w=900&q=80', 1),
  ('Toyota Avanza', 'https://images.unsplash.com/photo-1502877338535-766e1452684a?w=900&q=80', 2),
  ('Toyota Innova Zenix', 'https://images.unsplash.com/photo-1568605117036-5fe5e7bab0b7?w=900&q=80', 1),
  ('Toyota Innova Zenix', 'https://images.unsplash.com/photo-1552519507-da3b142c6e3d?w=900&q=80', 2),
  ('Toyota Hiace Premio', 'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?w=900&q=80', 1),
  ('Toyota Alphard', 'https://images.unsplash.com/photo-1503376780353-3e669a7b70b9?w=900&q=80', 1),
  ('Toyota Alphard', 'https://images.unsplash.com/photo-1494976388531-d1058494cdd8?w=900&q=80', 2),
  ('Mitsubishi Pajero Sport', 'https://images.unsplash.com/photo-1519641471654-76ce0107ad1b?w=900&q=80', 1),
  ('Toyota Fortuner', 'https://images.unsplash.com/photo-1533473359331-0135ef1b58bf?w=900&q=80', 1)
) as p(name, url, ord) on p.name = c.name
where not exists (
  select 1 from public.car_photos cp where cp.car_id = c.id and cp.url = p.url
);

-- car features mapping
insert into public.car_features (car_id, feature_id)
select c.id, f.id
from public.cars c
join (values
  ('Toyota Avanza', 'Air Conditioning'), ('Toyota Avanza', 'Bluetooth Audio'), ('Toyota Avanza', 'USB Charger'),
  ('Toyota Innova Zenix', 'Air Conditioning'), ('Toyota Innova Zenix', 'Bluetooth Audio'), ('Toyota Innova Zenix', 'USB Charger'), ('Toyota Innova Zenix', 'GPS Navigation'), ('Toyota Innova Zenix', 'Backup Camera'), ('Toyota Innova Zenix', 'Cruise Control'),
  ('Toyota Hiace Premio', 'Air Conditioning'), ('Toyota Hiace Premio', 'Bluetooth Audio'), ('Toyota Hiace Premio', 'USB Charger'),
  ('Toyota Alphard', 'Air Conditioning'), ('Toyota Alphard', 'Bluetooth Audio'), ('Toyota Alphard', 'USB Charger'), ('Toyota Alphard', 'GPS Navigation'), ('Toyota Alphard', 'Backup Camera'), ('Toyota Alphard', 'Child Seat'),
  ('Mitsubishi Pajero Sport', 'Air Conditioning'), ('Mitsubishi Pajero Sport', 'Bluetooth Audio'), ('Mitsubishi Pajero Sport', 'GPS Navigation'), ('Mitsubishi Pajero Sport', 'Roof Rack'), ('Mitsubishi Pajero Sport', 'Backup Camera'),
  ('Toyota Fortuner', 'Air Conditioning'), ('Toyota Fortuner', 'Bluetooth Audio'), ('Toyota Fortuner', 'GPS Navigation'), ('Toyota Fortuner', 'Roof Rack'), ('Toyota Fortuner', 'Backup Camera'), ('Toyota Fortuner', 'Cruise Control')
) as m(car_name, feature_name) on m.car_name = c.name
join public.features f on f.name = m.feature_name
on conflict do nothing;
