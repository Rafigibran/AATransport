-- A&A Transport - Perbaikan akun admin v2 (diagnosis + satu tempat edit)
-- Jalankan SELURUH file ini di Supabase SQL Editor (project jbowxiolzbbacfyatvoh).
-- Berbeda dari file 202610080003: di sini email hanya diganti di SATU baris
-- (ditandai -- GANTI SATU BARIS INI), dan langkah 1 menampilkan diagnosis
-- untuk semua akun, jadi penyebabnya langsung terlihat.

-- ===== 1) DIAGNOSIS: semua akun terdaftar vs profil & role-nya =====
-- Jalankan langkah ini saja dulu juga boleh: kolom "diagnosis" memberi tahu
-- persis masalahnya untuk tiap akun.
select
  u.email as email_terdaftar,
  u.email_confirmed_at,
  p.role,
  case
    when p.id is null then 'MASALAH: profil belum ada di tabel profiles'
    when p.role <> 'admin' then 'MASALAH: role masih "' || p.role || '" (belum admin)'
    else 'OK: sudah admin, login panel harusnya berhasil'
  end as diagnosis
from auth.users u
left join public.profiles p on p.id = u.id
order by u.created_at desc;
-- Kalau langkah ini menampilkan 0 baris, akunmu terdaftar di project Supabase
-- lain. Pastikan project yang terbuka adalah jbowxiolzbbacfyatvoh.

-- ===== 2) JADIKAN ADMIN =====
do $$
declare
  v_email text := 'email-login-kamu@contoh.com'; -- GANTI SATU BARIS INI
  v_count int;
begin
  insert into public.profiles (id, full_name, email, role)
  select
    u.id,
    coalesce(u.raw_user_meta_data ->> 'full_name', 'Admin'),
    u.email,
    'admin'
  from auth.users u
  where lower(u.email) = lower(v_email)
  on conflict (id) do update
    set role = 'admin',
        email = excluded.email;

  get diagnostics v_count = row_count;
  if v_count = 0 then
    raise notice 'GAGAL: tidak ada akun terdaftar dengan email "%". Lihat kolom email_terdaftar pada hasil langkah 1 - kemungkinan email yang dipakai mendaftar berbeda dari yang diketik di sini.', v_email;
  else
    raise notice 'BERHASIL: % akun dijadikan admin untuk email "%". Silakan logout lalu login lagi di admin panel.', v_count, v_email;
  end if;
end $$;

-- ===== 3) VERIFIKASI: email kamu harus tampil dengan role = admin =====
select email, role, created_at
from public.profiles
order by created_at desc;
