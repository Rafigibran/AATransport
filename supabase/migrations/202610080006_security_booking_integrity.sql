-- A&A Transport - booking, payment, and profile integrity (migration 006)
-- Run AFTER:
--   202610080001_init_aatransport.sql
--   202610080002_admin_panel.sql
--   202610080005_app_settings.sql
--
-- Why this migration exists:
-- * The old profile policy let any signed-in user update every column in
--   their own profile, including profiles.role, so a customer could promote
--   themselves to admin through the REST API.
-- * The old booking policy let a customer write any status/total/payment
--   field on their own booking and the app trusted a client-computed total.
-- * There was no fleet capacity or overlap rule, and an unpaid booking could
--   be shown as completed merely because its return date had passed.
--
-- This migration fixes those issues at the database layer while keeping the
-- current Flutter/admin clients working:
-- * customers create bookings only through create_booking_secure();
-- * the server recomputes days/subtotal/tax/fee/total from cars+app_settings;
-- * overlapping rentals reserve fleet units and cannot exceed cars.total_units;
-- * clients may only cancel their own unpaid/pending booking directly;
-- * admins keep full management access through public.is_admin().

-- ---------- fleet capacity ----------
alter table public.cars
  add column if not exists total_units integer not null default 1 check (total_units > 0);

-- ---------- profile role self-escalation guard ----------
create or replace function public.prevent_profile_role_self_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.role is distinct from old.role
     and auth.uid() is not null
     and not public.is_admin() then
    raise exception 'Hanya admin yang dapat mengubah role pengguna';
  end if;
  return new;
end;
$$;

drop trigger if exists profiles_prevent_role_self_change on public.profiles;
create trigger profiles_prevent_role_self_change
  before update of role on public.profiles
  for each row execute function public.prevent_profile_role_self_change();

-- ---------- public reviewer identity (name/avatar only via view) ----------
create or replace view public.reviewer_profiles as
select p.id, p.full_name, p.avatar_url
from public.profiles p
where exists (select 1 from public.reviews r where r.user_id = p.id);

grant select on public.reviewer_profiles to authenticated;

-- Reviews must belong to a paid, completed rental of the same car by the
-- same user. The view/function check happens in the policy below.
create or replace function public.can_review_booking(p_booking_id uuid, p_car_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.bookings b
    where b.id = p_booking_id
      and b.user_id = auth.uid()
      and b.car_id = p_car_id
      and b.payment_status = 'berhasil'
      and (b.status = 'completed' or (b.status = 'confirmed' and b.return_date < current_date))
  );
$$;

drop policy if exists "reviews_insert_own" on public.reviews;
create policy "reviews_insert_own" on public.reviews
  for insert with check (
    auth.uid() = user_id
    and (booking_id is null or public.can_review_booking(booking_id, car_id))
  );

-- ---------- direct client booking writes are deliberately narrow ----------
drop policy if exists "bookings_insert_own" on public.bookings;
create policy "bookings_insert_own" on public.bookings
  for insert with check (false);

drop policy if exists "bookings_update_own" on public.bookings;
create policy "bookings_update_own" on public.bookings
  for update
  using (
    auth.uid() = user_id
    and status = 'pending_payment'
    and payment_status <> 'berhasil'
  )
  with check (
    auth.uid() = user_id
    and status = 'cancelled'
    and payment_status <> 'berhasil'
  );

-- ---------- public availability check (aggregate only, no booking rows) ----------
create or replace function public.car_available_units(
  p_car_id uuid,
  p_pickup_date date,
  p_return_date date
)
returns integer
language sql
stable
security definer
set search_path = public
as $$
  select greatest(
    c.total_units - coalesce(sum(b.units) filter (
      where b.status not in ('cancelled', 'expired')
        and b.pickup_date <= p_return_date
        and b.return_date >= p_pickup_date
    ), 0), 0
  )::integer
  from public.cars c
  left join public.bookings b on b.car_id = c.id
  where c.id = p_car_id and c.is_active = true
  group by c.total_units;
$$;

revoke all on function public.car_available_units(uuid, date, date) from public;
grant execute on function public.car_available_units(uuid, date, date) to authenticated;

-- ---------- secure booking creation ----------
create or replace function public.create_booking_secure(
  p_car_id uuid,
  p_pickup_date date,
  p_return_date date,
  p_passengers integer,
  p_units integer,
  p_service_type text,
  p_customer_name text,
  p_customer_email text,
  p_customer_phone text,
  p_payment_method_code text
)
returns public.bookings
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_car public.cars%rowtype;
  v_settings public.app_settings%rowtype;
  v_days integer;
  v_subtotal integer;
  v_tax integer;
  v_fee integer;
  v_total integer;
  v_reserved_units integer;
  v_booking public.bookings%rowtype;
begin
  if v_user_id is null then
    raise exception 'Silakan login terlebih dahulu';
  end if;
  if p_return_date <= p_pickup_date then
    raise exception 'Tanggal kembali harus setelah tanggal ambil';
  end if;
  if p_passengers <= 0 then
    raise exception 'Jumlah penumpang harus lebih dari 0';
  end if;
  if p_units <= 0 then
    raise exception 'Jumlah unit harus lebih dari 0';
  end if;
  if coalesce(trim(p_customer_name), '') = ''
     or coalesce(trim(p_customer_email), '') = ''
     or coalesce(trim(p_customer_phone), '') = '' then
    raise exception 'Nama, email, dan nomor handphone penyewa wajib diisi';
  end if;

  -- Serialize capacity checks for this car so two simultaneous requests
  -- cannot both reserve the last available unit.
  perform pg_advisory_xact_lock(hashtext(p_car_id::text));

  select * into v_car
  from public.cars
  where id = p_car_id and is_active = true;

  if not found then
    raise exception 'Mobil tidak ditemukan atau sedang nonaktif';
  end if;
  if p_passengers > v_car.seats then
    raise exception 'Jumlah penumpang melebihi kapasitas % kursi', v_car.seats;
  end if;
  if p_units > v_car.total_units then
    raise exception 'Jumlah unit melebihi total armada % unit', v_car.total_units;
  end if;

  select coalesce(sum(units), 0) into v_reserved_units
  from public.bookings
  where car_id = p_car_id
    and status not in ('cancelled', 'expired')
    and pickup_date <= p_return_date
    and return_date >= p_pickup_date;

  if v_reserved_units + p_units > v_car.total_units then
    raise exception 'Mobil tidak tersedia pada tanggal tersebut. Sisa unit tersedia: %', greatest(v_car.total_units - v_reserved_units, 0);
  end if;

  select * into v_settings from public.app_settings where id = 1;
  if not found then
    v_settings.tax_percent := 0;
    v_settings.fee_percent := 0;
  end if;

  v_days := p_return_date - p_pickup_date;
  v_subtotal := v_car.price_per_day * v_days * p_units;
  v_tax := round(v_subtotal * coalesce(v_settings.tax_percent, 0) / 100.0)::integer;
  v_fee := round(v_subtotal * coalesce(v_settings.fee_percent, 0) / 100.0)::integer;
  v_total := v_subtotal + v_tax + v_fee;

  insert into public.bookings (
    user_id, car_id, pickup_date, return_date, passengers, units, service_type,
    customer_name, customer_email, customer_phone, days, subtotal, tax, fee,
    tax_percent, fee_percent, total, payment_method_code
  ) values (
    v_user_id, p_car_id, p_pickup_date, p_return_date, p_passengers, p_units,
    coalesce(nullif(trim(p_service_type), ''), 'Dengan Sopir'),
    trim(p_customer_name), trim(p_customer_email), trim(p_customer_phone),
    v_days, v_subtotal, v_tax, v_fee,
    coalesce(v_settings.tax_percent, 0), coalesce(v_settings.fee_percent, 0),
    v_total, p_payment_method_code
  ) returning * into v_booking;

  return v_booking;
end;
$$;

revoke all on function public.create_booking_secure(uuid, date, date, integer, integer, text, text, text, text, text) from public;
grant execute on function public.create_booking_secure(uuid, date, date, integer, integer, text, text, text, text, text) to authenticated;

-- ---------- storage hardening ----------
-- The public car-images bucket remains publicly readable, but ordinary app
-- users no longer need upload rights (the Flutter app never uploads). Admin
-- write policies from migration 002 remain the intended upload path.
drop policy if exists "car_images_auth_upload" on storage.objects;
