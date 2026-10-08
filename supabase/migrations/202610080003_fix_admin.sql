-- A&A Transport - Perbaikan akun admin
-- Jalankan file ini di Supabase SQL Editor (project jbowxiolzbbacfyatvoh).
-- GANTI email di bawah dengan email akun yang kamu pakai login admin panel.

-- 1) Lihat dulu akun yang terdaftar dan role-nya:
select id, email, role, created_at
from public.profiles
order by created_at desc;

-- 2) Jadikan admin (tidak peka huruf besar/kecil, dan membuat baris profil
--    otomatis dari auth.users kalau profilnya belum ada):
insert into public.profiles (id, full_name, email, role)
select
  u.id,
  coalesce(u.raw_user_meta_data ->> 'full_name', 'Admin'),
  u.email,
  'admin'
from auth.users u
where lower(u.email) = lower('GANTI-DENGAN-EMAIL-ADMIN-KAMU@contoh.com')
on conflict (id) do update
  set role = 'admin',
      email = excluded.email;

-- 3) Verifikasi hasil (harus menampilkan role = admin):
select email, role
from public.profiles
where lower(email) = lower('GANTI-DENGAN-EMAIL-ADMIN-KAMU@contoh.com');
