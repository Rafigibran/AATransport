-- Hipo - Supabase initial schema
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

-- ---------- hotels ----------
create table if not exists public.hotels (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  location text not null,
  description text not null default '',
  price_per_night integer not null check (price_per_night >= 0), -- IDR
  image_url text not null default '',
  rating numeric(3,2) not null default 0,
  review_count integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.hotel_photos (
  id uuid primary key default gen_random_uuid(),
  hotel_id uuid not null references public.hotels(id) on delete cascade,
  url text not null,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.facilities (
  id uuid primary key default gen_random_uuid(),
  name text not null unique
);

create table if not exists public.hotel_facilities (
  hotel_id uuid not null references public.hotels(id) on delete cascade,
  facility_id uuid not null references public.facilities(id) on delete cascade,
  primary key (hotel_id, facility_id)
);

-- ---------- favourites ----------
create table if not exists public.favourites (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  hotel_id uuid not null references public.hotels(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (user_id, hotel_id)
);

-- ---------- bookings & payments ----------
create table if not exists public.bookings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  hotel_id uuid not null references public.hotels(id) on delete restrict,
  check_in date not null,
  check_out date not null,
  guests integer not null default 1 check (guests > 0),
  rooms integer not null default 1 check (rooms > 0),
  room_type text not null default 'Economy Room',
  guest_name text not null,
  guest_email text not null,
  guest_phone text not null,
  nights integer not null check (nights > 0),
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
  check (check_out > check_in)
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
  hotel_id uuid not null references public.hotels(id) on delete cascade,
  booking_id uuid references public.bookings(id) on delete set null,
  rating integer not null check (rating between 1 and 5),
  comment text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (booking_id)
);

create or replace function public.refresh_hotel_rating()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  target_hotel uuid := coalesce(new.hotel_id, old.hotel_id);
begin
  update public.hotels h
  set rating = coalesce((select round(avg(r.rating)::numeric, 2) from public.reviews r where r.hotel_id = target_hotel), 0),
      review_count = (select count(*) from public.reviews r where r.hotel_id = target_hotel)
  where h.id = target_hotel;
  return coalesce(new, old);
end;
$$;

drop trigger if exists reviews_refresh_rating on public.reviews;
create trigger reviews_refresh_rating
  after insert or update or delete on public.reviews
  for each row execute function public.refresh_hotel_rating();

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
drop trigger if exists hotels_updated on public.hotels;
create trigger hotels_updated before update on public.hotels for each row execute function public.set_updated_at();
drop trigger if exists bookings_updated on public.bookings;
create trigger bookings_updated before update on public.bookings for each row execute function public.set_updated_at();
drop trigger if exists payments_updated on public.payments;
create trigger payments_updated before update on public.payments for each row execute function public.set_updated_at();
drop trigger if exists reviews_updated on public.reviews;
create trigger reviews_updated before update on public.reviews for each row execute function public.set_updated_at();

-- ---------- RLS ----------
alter table public.profiles enable row level security;
alter table public.hotels enable row level security;
alter table public.hotel_photos enable row level security;
alter table public.facilities enable row level security;
alter table public.hotel_facilities enable row level security;
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

-- hotels & catalogue: public read, writes only via service role (dashboard / SQL editor)
drop policy if exists "hotels_public_read" on public.hotels;
create policy "hotels_public_read" on public.hotels for select using (is_active = true);
drop policy if exists "hotel_photos_public_read" on public.hotel_photos;
create policy "hotel_photos_public_read" on public.hotel_photos for select using (true);
drop policy if exists "facilities_public_read" on public.facilities;
create policy "facilities_public_read" on public.facilities for select using (true);
drop policy if exists "hotel_facilities_public_read" on public.hotel_facilities;
create policy "hotel_facilities_public_read" on public.hotel_facilities for select using (true);

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

-- ---------- Storage: hotel images bucket (public read) ----------
insert into storage.buckets (id, name, public)
values ('hotel-images', 'hotel-images', true)
on conflict (id) do nothing;

drop policy if exists "hotel_images_public_read" on storage.objects;
create policy "hotel_images_public_read" on storage.objects for select
  using (bucket_id = 'hotel-images');
drop policy if exists "hotel_images_auth_upload" on storage.objects;
create policy "hotel_images_auth_upload" on storage.objects for insert
  with check (bucket_id = 'hotel-images' and auth.role() = 'authenticated');

-- ---------- Seed: facilities ----------
insert into public.facilities (name) values
  ('Free Wifi'), ('Restaurant'), ('Pool'), ('Gym'), ('Spa'), ('Parking'), ('Beach')
on conflict (name) do nothing;

-- ---------- Seed: hotels (prices in IDR) ----------
insert into public.hotels (name, location, description, price_per_night, image_url, rating, review_count)
values
  ('Elysium Gardens', 'California, USA', 'Elysium Gardens adalah hotel premium dengan kamar nyaman, kolam renang, spa, dan restoran kelas dunia. Cocok untuk liburan keluarga, perjalanan bisnis, maupun staycation.', 1500000, 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=900&q=80', 4.5, 0),
  ('Nexon Suites', 'California, USA', 'Suite modern dengan pemandangan kota, tempat tidur nyaman, dan akses mudah ke pusat kota.', 750000, 'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=900&q=80', 4.3, 0),
  ('Solara Springs', 'Florida, USA', 'Nikmati suasana tropis, kolam renang outdoor, dan akses pantai untuk liburan yang santai.', 525000, 'https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=900&q=80', 4.6, 0),
  ('Horizon Crest', 'New York, USA', 'Hotel elegan di pusat kota dengan layanan premium dan kamar yang luas.', 1650000, 'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=900&q=80', 4.4, 0),
  ('Ventura Vista', 'Texas, USA', 'Penginapan nyaman dengan kamar keluarga dan sarapan lezat.', 900000, 'https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=900&q=80', 4.2, 0),
  ('Peakview Inn', 'Colorado, USA', 'Inn dengan pemandangan pegunungan, suasana tenang, cocok untuk healing dan staycation.', 1050000, 'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=900&q=80', 4.7, 0)
on conflict do nothing;

-- photos
insert into public.hotel_photos (hotel_id, url, sort_order)
select h.id, p.url, p.ord
from public.hotels h
join (values
  ('Elysium Gardens', 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=900&q=80', 1),
  ('Elysium Gardens', 'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=900&q=80', 2),
  ('Elysium Gardens', 'https://images.unsplash.com/photo-1578683010236-d716f9a3f461?w=900&q=80', 3),
  ('Elysium Gardens', 'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=900&q=80', 4),
  ('Nexon Suites', 'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=900&q=80', 1),
  ('Nexon Suites', 'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=900&q=80', 2),
  ('Solara Springs', 'https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=900&q=80', 1),
  ('Solara Springs', 'https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=900&q=80', 2),
  ('Horizon Crest', 'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=900&q=80', 1),
  ('Ventura Vista', 'https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=900&q=80', 1),
  ('Peakview Inn', 'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=900&q=80', 1)
) as p(name, url, ord) on p.name = h.name
where not exists (
  select 1 from public.hotel_photos hp where hp.hotel_id = h.id and hp.url = p.url
);

-- hotel facilities mapping
insert into public.hotel_facilities (hotel_id, facility_id)
select h.id, f.id
from public.hotels h
join (values
  ('Elysium Gardens', 'Free Wifi'), ('Elysium Gardens', 'Restaurant'), ('Elysium Gardens', 'Pool'), ('Elysium Gardens', 'Gym'), ('Elysium Gardens', 'Spa'), ('Elysium Gardens', 'Parking'),
  ('Nexon Suites', 'Free Wifi'), ('Nexon Suites', 'Pool'), ('Nexon Suites', 'Gym'), ('Nexon Suites', 'Parking'),
  ('Solara Springs', 'Free Wifi'), ('Solara Springs', 'Beach'), ('Solara Springs', 'Pool'), ('Solara Springs', 'Restaurant'),
  ('Horizon Crest', 'Free Wifi'), ('Horizon Crest', 'Restaurant'), ('Horizon Crest', 'Gym'), ('Horizon Crest', 'Spa'),
  ('Ventura Vista', 'Free Wifi'), ('Ventura Vista', 'Pool'), ('Ventura Vista', 'Parking'),
  ('Peakview Inn', 'Free Wifi'), ('Peakview Inn', 'Spa'), ('Peakview Inn', 'Restaurant'), ('Peakview Inn', 'Parking')
) as m(hotel_name, facility_name) on m.hotel_name = h.name
join public.facilities f on f.name = m.facility_name
on conflict do nothing;
