import { useCallback, useEffect, useState } from 'react';
import { supabase, SUPABASE_URL } from './supabaseClient';

const rupiah = (n) =>
  'Rp' + Math.round(Number(n || 0)).toString().replace(/\B(?=(\d{3})+(?!\d))/g, '.');
const dateId = (d) => {
  if (!d) return '-';
  const x = new Date(d);
  return Number.isNaN(x.getTime())
    ? String(d)
    : x.toLocaleDateString('id-ID', { day: 'numeric', month: 'short', year: 'numeric' });
};
const Badge = ({ children, kind = 'grey' }) => <span className={`badge ${kind}`}>{children}</span>;
const paymentBadge = (s) =>
  s === 'berhasil' ? <Badge kind="green">Berhasil</Badge>
  : s === 'expired' ? <Badge kind="red">Kedaluwarsa</Badge>
  : <Badge kind="orange">Pending</Badge>;
const bookingBadge = (s) =>
  ({ confirmed: <Badge kind="green">Terkonfirmasi</Badge>, completed: <Badge kind="blue">Selesai</Badge>,
     cancelled: <Badge kind="red">Dibatalkan</Badge>, expired: <Badge kind="red">Kedaluwarsa</Badge>,
     pending_payment: <Badge kind="orange">Menunggu Pembayaran</Badge> })[s] || <Badge>{s}</Badge>;

const NAV = [
  ['dashboard', '📊 Dashboard', 'Ringkasan bisnis A&A Transport'],
  ['cars', '🚘 Mobil', 'Kelola armada, harga, foto, dan fitur mobil'],
  ['bookings', '📅 Booking', 'Kelola rental pelanggan dan status perjalanan'],
  ['calendar', '🗓️ Kalender Rental', 'Jadwal pengambilan mobil berdasarkan tanggal'],
  ['payments', '💳 Pembayaran', 'Transaksi SakuRupiah dan pendapatan'],
  ['customers', '👥 Pelanggan', 'Akun pelanggan aplikasi A&A Transport'],
  ['reviews', '⭐ Review', 'Ulasan pelanggan untuk setiap mobil'],
  ['reports', '📈 Laporan', 'Ekspor CSV dan ringkasan performa'],
  ['logs', '🧾 Log Admin', 'Riwayat aktivitas admin panel'],
  ['settings', '⚙️ Pengaturan', 'Konfigurasi Supabase, SakuRupiah, dan hak akses'],
];

function downloadCsv(filename, rows) {
  if (!rows.length) return;
  const headers = Object.keys(rows[0]);
  const csv = [headers.join(','), ...rows.map((r) => headers.map((h) => `"${String(r[h] ?? '').replaceAll('"', '""')}"`).join(','))].join('\n');
  const a = document.createElement('a');
  a.href = URL.createObjectURL(new Blob([csv], { type: 'text/csv' }));
  a.download = filename;
  a.click();
  URL.revokeObjectURL(a.href);
}

function StatCard({ label, value, sub }) {
  return <div className="card stat"><div className="label">{label}</div><div className="value">{value}</div><div className="sub">{sub || ''}</div></div>;
}

function BookingTable({ list, compact = false, onDetail, onCheck }) {
  return (
    <div className="table-wrap"><table>
      <thead><tr><th>Booking</th><th>Mobil</th><th>Penyewa</th><th>Ambil</th><th>Total</th><th>Pembayaran</th><th>Status</th>{!compact && <th>Aksi</th>}</tr></thead>
      <tbody>{list.map((b) => (
        <tr key={b.id}>
          <td><b>{String(b.id).slice(0, 8).toUpperCase()}</b><div className="muted small">{dateId(b.created_at)}</div></td>
          <td>{b.cars?.name || '-'}</td>
          <td>{b.customer_name}<div className="muted small">{b.customer_phone}</div></td>
          <td>{dateId(b.pickup_date)}<div className="muted small">s/d {dateId(b.return_date)} ({b.days} hari)</div></td>
          <td><b>{rupiah(b.total)}</b></td><td>{paymentBadge(b.payment_status)}</td><td>{bookingBadge(b.status)}</td>
          {!compact && <td><div className="actions"><button className="btn small" onClick={() => onDetail(b)}>Detail</button><button className="btn small" onClick={() => onCheck(b.id)}>Cek Bayar</button></div></td>}
        </tr>))}
        {!list.length && <tr><td colSpan="8">Tidak ada booking.</td></tr>}
      </tbody></table></div>
  );
}

function LoginPage({ onLoggedIn }) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const submit = async (e) => {
    e.preventDefault();
    setError('');
    const { data, error: err } = await supabase.auth.signInWithPassword({ email: email.trim(), password });
    if (err) return setError(err.message);
    const { data: prof } = await supabase.from('profiles').select('*').eq('id', data.user.id).maybeSingle();
    if (!prof) {
      await supabase.auth.signOut();
      return setError('Profil akun ini belum ada di tabel profiles. Jalankan SQL file 202610080003_fix_admin.sql di Supabase SQL Editor, lalu login lagi.');
    }
    if (prof.role !== 'admin') {
      await supabase.auth.signOut();
      return setError(`Akun ${prof.email || email} masih berstatus role "${prof.role}". Jalankan SQL file 202610080003_fix_admin.sql untuk menjadikannya admin, lalu login lagi.`);
    }
    await onLoggedIn(data.session);
  };
  return (
    <section className="login-wrap">
      <div className="login-card">
        <div className="brand brand-center"><span className="brand-badge"><img src="/favicon.svg" alt="A&A Transport" /></span><div><h1>A&A Transport</h1><p>Admin Panel</p></div></div>
        <form onSubmit={submit}>
          <label>Email admin<input type="email" required value={email} onChange={(e) => setEmail(e.target.value)} placeholder="admin@contoh.com" /></label>
          <label>Password<input type="password" required value={password} onChange={(e) => setPassword(e.target.value)} placeholder="••••••••" /></label>
          <button className="btn primary full" type="submit">Masuk Dashboard</button>
          {error && <p className="error">{error}</p>}
        </form>
        <p className="hint">Login hanya untuk akun dengan role <b>admin</b>. Panduan membuat admin pertama ada di <code>ADMIN_PANEL_SETUP.md</code>.</p>
      </div>
    </section>
  );
}

function Dashboard({ data }) {
  const paid = data.bookings.filter((b) => b.payment_status === 'berhasil');
  const revenue = paid.reduce((a, b) => a + Number(b.total || 0), 0);
  const pending = data.bookings.filter((b) => b.status === 'pending_payment');
  const upcoming = data.bookings.filter((b) => b.status === 'confirmed' && new Date(b.pickup_date) >= new Date(new Date().toDateString()));
  const last7 = [...Array(7)].map((_, i) => {
    const d = new Date(); d.setDate(d.getDate() - (6 - i));
    const key = d.toISOString().slice(0, 10);
    const sum = data.payments.filter((p) => p.status === 'berhasil' && String(p.created_at).slice(0, 10) === key).reduce((a, p) => a + Number(p.amount || 0), 0);
    return { label: d.toLocaleDateString('id-ID', { weekday: 'short' }), sum };
  });
  const max = Math.max(...last7.map((x) => x.sum), 1);
  const popular = [...data.cars].sort((a, b) => Number(b.rating || 0) - Number(a.rating || 0)).slice(0, 5);
  return (
    <>
      <div className="grid stats">
        <StatCard label="Total Pendapatan" value={rupiah(revenue)} sub={`${paid.length} pembayaran berhasil`} />
        <StatCard label="Total Booking" value={data.bookings.length} sub={`${pending.length} menunggu pembayaran`} />
        <StatCard label="Mobil Aktif" value={data.cars.filter((c) => c.is_active).length} sub={`${data.cars.length} total armada`} />
        <StatCard label="Pelanggan" value={data.customers.length} sub={`${upcoming.length} rental akan datang`} />
      </div>
      <div className="grid two" style={{ marginTop: 16 }}>
        <div className="card"><h3>Pendapatan 7 Hari Terakhir</h3>{last7.map((x, i) => <div className="bar-row" key={i}><span>{x.label}</span><div className="bar"><i style={{ width: `${(x.sum / max) * 100}%` }} /></div><b>{rupiah(x.sum)}</b></div>)}</div>
        <div className="card"><h3>Mobil Rating Tertinggi</h3>{popular.map((c) => <div className="bar-row" key={c.id}><span>{c.name}</span><div className="bar"><i style={{ width: `${Number(c.rating || 0) * 20}%` }} /></div><b>⭐ {c.rating || 0} ({c.review_count || 0})</b></div>)}</div>
      </div>
      <div className="card" style={{ marginTop: 16 }}><h3>Booking Terbaru</h3><BookingTable list={data.bookings.slice(0, 8)} compact /></div>
    </>
  );
}

function CarsPage({ data, search, reload, logAdmin, toast, setModal }) {
  const q = search.toLowerCase();
  const list = data.cars.filter((c) => !q || c.name.toLowerCase().includes(q) || c.location.toLowerCase().includes(q));
  const toggleActive = async (c) => {
    const { error } = await supabase.from('cars').update({ is_active: !c.is_active }).eq('id', c.id);
    if (error) return toast(error.message, true);
    await logAdmin(c.is_active ? 'car_deactivate' : 'car_activate', 'cars', c.id);
    toast('Status mobil diperbarui'); await reload();
  };
  const openEditor = (car) => {
    const c = car || {};
    const selected = new Set((c.car_features || []).map((x) => x.feature_id));
    setModal({
      title: car ? 'Edit Mobil' : 'Tambah Mobil',
      body: (
        <form onSubmit={async (e) => {
          e.preventDefault();
          const fd = new FormData(e.target);
          const payload = { name: fd.get('name'), location: fd.get('location'), price_per_day: Number(fd.get('price_per_day')), image_url: fd.get('image_url'), car_type: fd.get('car_type'), seats: Number(fd.get('seats')), transmission: fd.get('transmission'), fuel_type: fd.get('fuel_type'), baggage: Number(fd.get('baggage')), total_units: Math.max(1, Number(fd.get('total_units') || 1)), is_active: fd.get('is_active') === 'true', description: fd.get('description') };
          let res = car ? await supabase.from('cars').update(payload).eq('id', car.id).select().single() : await supabase.from('cars').insert(payload).select().single();
          if (res.error && String(res.error.message || '').toLowerCase().includes('total_units')) {
            const legacyPayload = { ...payload };
            delete legacyPayload.total_units;
            res = car ? await supabase.from('cars').update(legacyPayload).eq('id', car.id).select().single() : await supabase.from('cars').insert(legacyPayload).select().single();
          }
          if (res.error) return toast(res.error.message, true);
          await supabase.from('car_features').delete().eq('car_id', res.data.id);
          const ids = fd.getAll('feature');
          if (ids.length) await supabase.from('car_features').insert(ids.map((feature_id) => ({ car_id: res.data.id, feature_id })));
          await logAdmin(car ? 'car_update' : 'car_create', 'cars', res.data.id, payload);
          setModal(null); toast('Mobil tersimpan dan langsung tampil di aplikasi'); await reload();
        }}>
          <div className="form-grid">
            <label>Nama mobil<input name="name" required defaultValue={c.name || ''} placeholder="Toyota Avanza" /></label>
            <label>Lokasi / kota<input name="location" required defaultValue={c.location || 'Makassar'} /></label>
            <label>Harga per hari (Rp)<input name="price_per_day" type="number" min="0" required defaultValue={c.price_per_day || 350000} /></label>
            <label>URL foto utama<input name="image_url" defaultValue={c.image_url || ''} /></label>
            <label>Tipe mobil<select name="car_type" defaultValue={c.car_type || 'MPV'}>{['MPV', 'SUV', 'Van', 'Premium', 'City Car', 'Pickup'].map((t) => <option key={t}>{t}</option>)}</select></label>
            <label>Jumlah kursi<input name="seats" type="number" min="1" defaultValue={c.seats || 7} /></label>
            <label>Transmisi<select name="transmission" defaultValue={c.transmission || 'Automatic'}>{['Automatic', 'Manual'].map((t) => <option key={t}>{t}</option>)}</select></label>
            <label>Bahan bakar<select name="fuel_type" defaultValue={c.fuel_type || 'Bensin'}>{['Bensin', 'Diesel', 'Hybrid', 'Listrik'].map((t) => <option key={t}>{t}</option>)}</select></label>
            <label>Kapasitas bagasi<input name="baggage" type="number" min="0" defaultValue={c.baggage ?? 2} /></label>
            <label>Total unit armada<input name="total_units" type="number" min="1" defaultValue={c.total_units || 1} /></label>
            <label>Status<select name="is_active" defaultValue={String(c.is_active !== false)}><option value="true">Aktif</option><option value="false">Nonaktif</option></select></label>
            <label className="wide">Deskripsi<textarea name="description" rows="4" defaultValue={c.description || ''} /></label>
          </div>
          <h4>Fitur mobil</h4>
          <div className="checks">{data.features.map((f) => <label key={f.id}><input type="checkbox" name="feature" value={f.id} defaultChecked={selected.has(f.id)} /> {f.name}</label>)}</div>
          <div style={{ display: 'flex', gap: 10, marginTop: 20 }}>
            <button className="btn primary" type="submit">Simpan Mobil</button>
            {car && <button className="btn danger" type="button" onClick={async () => {
              if (!confirm('Hapus mobil ini permanen? Lebih aman nonaktifkan mobil. Tetap hapus?')) return;
              const { error } = await supabase.from('cars').delete().eq('id', car.id);
              if (error) return toast(error.message, true);
              await logAdmin('car_delete', 'cars', car.id); setModal(null); await reload();
            }}>Hapus Permanen</button>}
          </div>
        </form>
      ),
    });
  };
  const openPhotos = (car) => {
    const photos = [...(car.car_photos || [])].sort((a, b) => (a.sort_order || 0) - (b.sort_order || 0));
    setModal({
      title: 'Foto ' + car.name,
      body: (
        <div>
          {photos.map((p, i) => (
            <div className="bar-row" key={i}><span>Foto {i + 1}</span><input value={p.url} readOnly /><button className="btn danger small" onClick={async () => {
              const { error } = await supabase.from('car_photos').delete().eq('car_id', car.id).eq('url', p.url);
              if (error) return toast(error.message, true);
              await logAdmin('car_photo_delete', 'cars', car.id); setModal(null); await reload();
            }}>Hapus</button></div>
          ))}
          {!photos.length && <p className="muted">Belum ada foto tambahan.</p>}
          <form onSubmit={async (e) => {
            e.preventDefault();
            const url = new FormData(e.target).get('url');
            const { error } = await supabase.from('car_photos').insert({ car_id: car.id, url, sort_order: photos.length + 1 });
            if (error) return toast(error.message, true);
            await logAdmin('car_photo_add', 'cars', car.id, { url }); setModal(null); await reload();
          }}>
            <label>Tambah URL foto<input name="url" required placeholder="https://images.unsplash.com/..." /></label>
            <button className="btn primary">Tambah Foto dari URL</button>
          </form>
          <form onSubmit={async (e) => {
            e.preventDefault();
            const file = new FormData(e.target).get('photo');
            if (!file || !file.size) return toast('Pilih file foto terlebih dahulu', true);
            const safeName = String(file.name || 'car-photo').replace(/[^a-zA-Z0-9._-]/g, '-');
            const path = `${car.id}/${Date.now()}-${safeName}`;
            const upload = await supabase.storage.from('car-images').upload(path, file, { cacheControl: '3600', upsert: false });
            if (upload.error) return toast(upload.error.message, true);
            const { data: publicData } = supabase.storage.from('car-images').getPublicUrl(path);
            const { error } = await supabase.from('car_photos').insert({ car_id: car.id, url: publicData.publicUrl, sort_order: photos.length + 1 });
            if (error) return toast(error.message, true);
            await logAdmin('car_photo_upload', 'cars', car.id, { path }); setModal(null); await reload();
          }}>
            <label>Upload foto ke Storage<input name="photo" type="file" accept="image/*" required /></label>
            <button className="btn">Upload Foto</button>
          </form>
          <p className="hint">Foto utama diatur dari form Edit Mobil. Upload memakai bucket publik <code>car-images</code>.</p>
        </div>
      ),
    });
  };
  const openFeatures = () => {
    setModal({
      title: 'Kelola Fitur Mobil',
      body: (
        <div>
          {data.features.map((f) => (
            <form key={f.id} className="bar-row" onSubmit={async (e) => {
              e.preventDefault();
              const name = new FormData(e.target).get('name');
              const { error } = await supabase.from('features').update({ name }).eq('id', f.id);
              if (error) return toast(error.message, true);
              await logAdmin('feature_update', 'features', f.id, { name }); setModal(null); await reload();
            }}>
              <input name="name" defaultValue={f.name} required />
              <button className="btn small">Simpan</button>
              <button className="btn danger small" type="button" onClick={async () => {
                if (!confirm(`Hapus fitur ${f.name}?`)) return;
                const { error } = await supabase.from('features').delete().eq('id', f.id);
                if (error) return toast(error.message, true);
                await logAdmin('feature_delete', 'features', f.id); setModal(null); await reload();
              }}>Hapus</button>
            </form>
          ))}
          {!data.features.length && <p className="muted">Belum ada fitur.</p>}
          <form onSubmit={async (e) => {
            e.preventDefault();
            const name = new FormData(e.target).get('name');
            const { error } = await supabase.from('features').insert({ name });
            if (error) return toast(error.message, true);
            await logAdmin('feature_create', 'features', null, { name }); setModal(null); await reload();
          }}>
            <label>Tambah fitur baru<input name="name" required placeholder="Contoh: Kamera Mundur" /></label>
            <button className="btn primary">Tambah Fitur</button>
          </form>
        </div>
      ),
    });
  };
  return (
    <>
      <div className="toolbar"><button className="btn primary" onClick={() => openEditor(null)}>+ Tambah Mobil</button><button className="btn" onClick={openFeatures}>Kelola Fitur</button><span className="spacer" /><span className="muted">{list.length} mobil</span></div>
      <div className="table-wrap"><table><thead><tr><th>Foto</th><th>Mobil</th><th>Lokasi</th><th>Harga</th><th>Rating</th><th>Status</th><th>Aksi</th></tr></thead>
        <tbody>{list.map((c) => (
          <tr key={c.id}><td>{c.image_url && <img className="thumb" src={c.image_url} alt="" />}</td>
            <td><b>{c.name}</b><div className="muted small">{c.car_type} • {c.seats} kursi • {c.transmission}</div></td>
            <td>{c.location}</td><td><b>{rupiah(c.price_per_day)}</b>/hari</td><td>⭐ {c.rating || 0} ({c.review_count || 0})</td>
            <td>{c.is_active ? <Badge kind="green">Aktif</Badge> : <Badge>Nonaktif</Badge>}</td>
            <td><div className="actions"><button className="btn small" onClick={() => openEditor(c)}>Edit</button><button className="btn small" onClick={() => openPhotos(c)}>Foto</button><button className="btn small" onClick={() => toggleActive(c)}>{c.is_active ? 'Nonaktifkan' : 'Aktifkan'}</button></div></td></tr>
        ))}{!list.length && <tr><td colSpan="7">Belum ada mobil.</td></tr>}</tbody></table></div>
    </>
  );
}

function useCheckPayment(reload, logAdmin, toast) {
  return async (bookingId) => {
    toast('Mengecek status ke SakuRupiah...');
    const { data, error } = await supabase.functions.invoke('check-payment', { body: { booking_id: bookingId } });
    if (error) return toast(error.message, true);
    if (data?.error) return toast(data.error, true);
    await logAdmin('payment_check', 'bookings', bookingId, data);
    toast('Status pembayaran: ' + (data.status || '-'));
    await reload();
  };
}

function BookingsPage({ data, search, reload, logAdmin, toast, setModal, bookingStatus, setBookingStatus, paymentStatus, setPaymentStatus }) {
  const checkPayment = useCheckPayment(reload, logAdmin, toast);
  const q = search.toLowerCase();
  const list = data.bookings.filter((b) => (!bookingStatus || b.status === bookingStatus) && (!paymentStatus || b.payment_status === paymentStatus) && (!q || b.customer_name.toLowerCase().includes(q) || (b.cars?.name || '').toLowerCase().includes(q) || b.id.toLowerCase().includes(q)));
  const detail = (b) => setModal({
    title: 'Detail Booking',
    body: (
      <div>
        <dl className="kv"><dt>ID Booking</dt><dd>{b.id}</dd><dt>Mobil</dt><dd>{b.cars?.name || '-'}</dd><dt>Penyewa</dt><dd>{b.customer_name}</dd><dt>Email</dt><dd>{b.customer_email}</dd><dt>Telepon</dt><dd>{b.customer_phone}</dd><dt>Tanggal</dt><dd>{dateId(b.pickup_date)} s/d {dateId(b.return_date)} ({b.days} hari)</dd><dt>Layanan</dt><dd>{b.service_type} • {b.units} mobil • {b.passengers} penumpang</dd><dt>Subtotal</dt><dd>{rupiah(b.subtotal)}</dd><dt>Pajak</dt><dd>{rupiah(b.tax)} ({b.tax_percent ?? 0}%)</dd><dt>Fee</dt><dd>{rupiah(b.fee || 0)} ({b.fee_percent ?? 0}%)</dd><dt>Total</dt><dd>{rupiah(b.total)}</dd><dt>Metode</dt><dd>{b.payment_method_code || '-'} via SakuRupiah</dd><dt>Transaksi</dt><dd>{b.sakurupiah_trx_id || '-'}</dd><dt>No. VA/Pembayaran</dt><dd>{b.payment_no || '-'}</dd></dl>
        <h4>Ubah Status Booking</h4>
        <div className="actions">{['pending_payment', 'confirmed', 'completed', 'cancelled', 'expired'].map((s) => (
          <button key={s} className="btn small" onClick={async () => {
            const { error } = await supabase.from('bookings').update({ status: s }).eq('id', b.id);
            if (error) return toast(error.message, true);
            await logAdmin('booking_status_update', 'bookings', b.id, { status: s });
            toast('Status booking diperbarui'); setModal(null); await reload();
          }}>{s}</button>))}
        </div>
        <div style={{ marginTop: 16 }} className="actions">
          <button className="btn primary" onClick={() => checkPayment(b.id)}>Cek Status SakuRupiah</button>
          {b.checkout_url && <a className="btn" href={b.checkout_url} target="_blank" rel="noreferrer">Buka Checkout</a>}
        </div>
      </div>
    ),
  });
  return (
    <>
      <div className="toolbar">
        <select value={bookingStatus} onChange={(e) => setBookingStatus(e.target.value)}><option value="">Semua status booking</option>{['pending_payment', 'confirmed', 'completed', 'cancelled', 'expired'].map((s) => <option key={s} value={s}>{s}</option>)}</select>
        <select value={paymentStatus} onChange={(e) => setPaymentStatus(e.target.value)}><option value="">Semua pembayaran</option>{['pending', 'berhasil', 'expired', 'failed'].map((s) => <option key={s} value={s}>{s}</option>)}</select>
        <button className="btn" onClick={() => downloadCsv('bookings.csv', list.map((b) => ({ id: b.id, mobil: b.cars?.name || '', penyewa: b.customer_name, email: b.customer_email, telepon: b.customer_phone, ambil: b.pickup_date, kembali: b.return_date, hari: b.days, total: b.total, status: b.status, pembayaran: b.payment_status, metode: b.payment_method_code || '' })))}>Ekspor CSV</button>
      </div>
      <BookingTable list={list} onDetail={detail} onCheck={checkPayment} />
    </>
  );
}

function CalendarPage({ data, setModal, reload, toast }) {
  const [cursor, setCursor] = useState(() => { const d = new Date(); return new Date(d.getFullYear(), d.getMonth(), 1); });
  const now = cursor;
  const days = new Date(now.getFullYear(), now.getMonth() + 1, 0).getDate();
  const moveMonth = (delta) => setCursor((current) => new Date(current.getFullYear(), current.getMonth() + delta, 1));
  const openBooking = (b) => setModal({
    title: 'Booking ' + String(b.id).slice(0, 8).toUpperCase(),
    body: (
      <div><p><b>{b.cars?.name}</b> — {b.customer_name}</p>
        <p className="muted">{dateId(b.pickup_date)} s/d {dateId(b.return_date)} • {rupiah(b.total)} • {b.status}</p>
        <button className="btn primary" onClick={async () => {
          const { data: res, error } = await supabase.functions.invoke('check-payment', { body: { booking_id: b.id } });
          if (error) return toast(error.message, true);
          toast('Status: ' + (res?.status || '-')); setModal(null); await reload();
        }}>Cek Status Pembayaran</button></div>
    ),
  });
  return (
    <div className="card"><div className="actions" style={{ justifyContent: 'space-between', marginBottom: 14 }}><h3 style={{ margin: 0 }}>{now.toLocaleDateString('id-ID', { month: 'long', year: 'numeric' })} — masa sewa aktif</h3><div className="actions"><button className="btn small" onClick={() => moveMonth(-1)}>Bulan sebelumnya</button><button className="btn small" onClick={() => { const d = new Date(); setCursor(new Date(d.getFullYear(), d.getMonth(), 1)); }}>Bulan ini</button><button className="btn small" onClick={() => moveMonth(1)}>Bulan berikutnya</button></div></div>
      <div className="calendar">{[...Array(days)].map((_, i) => {
        const d = i + 1;
        const key = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(d).padStart(2, '0')}`;
        const items = data.bookings.filter((b) => b.status !== 'cancelled' && b.pickup_date <= key && b.return_date >= key);
        return <div className="day" key={key}><div className="date">{d}</div>{items.map((b) => <div className="item" key={b.id} onClick={() => openBooking(b)}>{b.pickup_date === key ? 'Ambil: ' : 'Sewa: '}{b.cars?.name || 'Mobil'}<br />{b.customer_name}</div>)}</div>;
      })}</div></div>
  );
}

function PaymentsPage({ data, reload, logAdmin, toast }) {
  const [status, setStatus] = useState('');
  const checkPayment = useCheckPayment(reload, logAdmin, toast);
  const list = data.payments.filter((p) => !status || p.status === status);
  const revenue = data.payments.filter((p) => p.status === 'berhasil').reduce((a, p) => a + Number(p.amount || 0), 0);
  return (
    <>
      <div className="grid stats" style={{ marginBottom: 16 }}>
        <StatCard label="Pendapatan Berhasil" value={rupiah(revenue)} sub="Pembayaran SakuRupiah berhasil" />
        <StatCard label="Transaksi" value={data.payments.length} sub={`${data.payments.filter((p) => p.status === 'pending').length} pending`} />
      </div>
      <div className="toolbar">
        <select value={status} onChange={(e) => setStatus(e.target.value)}><option value="">Semua status</option>{['pending', 'berhasil', 'expired', 'failed'].map((s) => <option key={s}>{s}</option>)}</select>
        <button className="btn" onClick={() => downloadCsv('payments.csv', list.map((p) => ({ tanggal: p.created_at, trx_id: p.trx_id || '', merchant_ref: p.merchant_ref, metode: p.method_code, jumlah: p.amount, status: p.status, booking_id: p.booking_id })))}>Ekspor CSV</button>
      </div>
      <div className="table-wrap"><table><thead><tr><th>Tanggal</th><th>Transaksi</th><th>Booking</th><th>Metode</th><th>Jumlah</th><th>Status</th><th>Aksi</th></tr></thead>
        <tbody>{list.map((p) => <tr key={p.id}><td>{dateId(p.created_at)}</td><td><b>{p.trx_id || '-'}</b><div className="muted small">{p.merchant_ref}</div></td><td>{p.bookings?.cars?.name || '-'}<div className="muted small">{p.bookings?.customer_name || ''}</div></td><td>{p.method_code}</td><td><b>{rupiah(p.amount)}</b></td><td>{paymentBadge(p.status)}</td><td><button className="btn small" onClick={() => checkPayment(p.booking_id)}>Cek Status</button></td></tr>)}
          {!list.length && <tr><td colSpan="7">Belum ada pembayaran.</td></tr>}</tbody></table></div>
    </>
  );
}

function CustomersPage({ data, search, reload, logAdmin, toast, setModal, currentUserId }) {
  const q = search.toLowerCase();
  const list = data.customers.filter((c) => !q || (c.full_name || '').toLowerCase().includes(q) || (c.email || '').toLowerCase().includes(q));
  const edit = (c) => setModal({
    title: 'Edit Pelanggan',
    body: (
      <form onSubmit={async (e) => {
        e.preventDefault();
        const fd = new FormData(e.target);
        const payload = { full_name: fd.get('full_name'), phone: fd.get('phone'), avatar_url: fd.get('avatar_url') || null };
        const { error } = await supabase.from('profiles').update(payload).eq('id', c.id);
        if (error) return toast(error.message, true);
        await logAdmin('customer_update', 'profiles', c.id, payload); setModal(null); await reload();
      }}>
        <label>Nama<input name="full_name" defaultValue={c.full_name || ''} /></label>
        <label>No. handphone<input name="phone" defaultValue={c.phone || ''} /></label>
        <label>URL avatar<input name="avatar_url" defaultValue={c.avatar_url || ''} /></label>
        <button className="btn primary">Simpan</button>
      </form>
    ),
  });
  const toggleRole = async (c) => {
    const role = c.role === 'admin' ? 'user' : 'admin';
    if (c.id === currentUserId && role !== 'admin') return toast('Kamu tidak bisa menurunkan role akunmu sendiri.', true);
    if (!confirm(`Ubah role user ini menjadi ${role}?`)) return;
    const { error } = await supabase.from('profiles').update({ role }).eq('id', c.id);
    if (error) return toast(error.message, true);
    await logAdmin('customer_role_update', 'profiles', c.id, { role }); await reload();
  };
  return (
    <div className="table-wrap"><table><thead><tr><th>Pelanggan</th><th>Kontak</th><th>Role</th><th>Booking</th><th>Bergabung</th><th>Aksi</th></tr></thead>
      <tbody>{list.map((c) => (
        <tr key={c.id}><td><b>{c.full_name || 'Tanpa nama'}</b></td><td>{c.email}<div className="muted small">{c.phone || '-'}</div></td>
          <td>{c.role === 'admin' ? <Badge kind="blue">Admin</Badge> : <Badge>User</Badge>}</td>
          <td>{data.bookings.filter((b) => b.user_id === c.id).length}</td><td>{dateId(c.created_at)}</td>
          <td><div className="actions"><button className="btn small" onClick={() => edit(c)}>Edit</button><button className="btn small" onClick={() => toggleRole(c)}>{c.role === 'admin' ? 'Jadikan User' : 'Jadikan Admin'}</button></div></td></tr>
      ))}{!list.length && <tr><td colSpan="6">Belum ada pelanggan.</td></tr>}</tbody></table></div>
  );
}

function ReviewsPage({ data, reload, logAdmin, toast }) {
  return (
    <div className="table-wrap"><table><thead><tr><th>Tanggal</th><th>Mobil</th><th>Pelanggan</th><th>Rating</th><th>Komentar</th><th>Aksi</th></tr></thead>
      <tbody>{data.reviews.map((r) => (
        <tr key={r.id}><td>{dateId(r.created_at)}</td><td>{r.cars?.name || '-'}</td><td>{r.profiles?.full_name || 'Pengguna'}<div className="muted small">{r.profiles?.email || ''}</div></td>
          <td>{'⭐'.repeat(Number(r.rating || 0))}</td><td>{r.comment}</td>
          <td><button className="btn danger small" onClick={async () => { if (!confirm('Hapus review ini?')) return; const { error } = await supabase.from('reviews').delete().eq('id', r.id); if (error) return toast(error.message, true); await logAdmin('review_delete', 'reviews', r.id); await reload(); }}>Hapus</button></td></tr>
      ))}{!data.reviews.length && <tr><td colSpan="6">Belum ada review.</td></tr>}</tbody></table></div>
  );
}

function ReportsPage({ data, toast }) {
  const paid = data.bookings.filter((b) => b.payment_status === 'berhasil');
  const revenue = paid.reduce((a, b) => a + Number(b.total || 0), 0);
  const byCar = data.cars.map((c) => ({ car: c, count: data.bookings.filter((b) => b.car_id === c.id).length, income: data.bookings.filter((b) => b.car_id === c.id && b.payment_status === 'berhasil').reduce((a, b) => a + Number(b.total || 0), 0) })).sort((a, b) => b.income - a.income);
  const exporters = {
    bookings: () => downloadCsv('bookings.csv', data.bookings.map((b) => ({ id: b.id, mobil: b.cars?.name || '', penyewa: b.customer_name, ambil: b.pickup_date, kembali: b.return_date, total: b.total, status: b.status, pembayaran: b.payment_status }))),
    payments: () => downloadCsv('payments.csv', data.payments.map((p) => ({ tanggal: p.created_at, trx_id: p.trx_id || '', metode: p.method_code, jumlah: p.amount, status: p.status }))),
    cars: () => downloadCsv('cars.csv', data.cars.map((c) => ({ nama: c.name, lokasi: c.location, harga_per_hari: c.price_per_day, tipe: c.car_type, rating: c.rating, aktif: c.is_active }))),
    customers: () => downloadCsv('customers.csv', data.customers.map((c) => ({ nama: c.full_name, email: c.email, telepon: c.phone || '', role: c.role }))),
  };
  return (
    <>
      <div className="grid three">
        <StatCard label="Pendapatan" value={rupiah(revenue)} sub="Booking terbayar" />
        <StatCard label="Rata-rata Booking" value={rupiah(paid.length ? revenue / paid.length : 0)} sub="Per transaksi berhasil" />
        <StatCard label="Tingkat Selesai Bayar" value={`${data.bookings.length ? Math.round((paid.length / data.bookings.length) * 100) : 0}%`} sub="Dari semua booking" />
      </div>
      <div className="card" style={{ marginTop: 16 }}><h3>Performa Mobil</h3>{byCar.map((x) => <div className="bar-row" key={x.car.id}><span>{x.car.name}</span><div className="bar"><i style={{ width: `${revenue ? (x.income / revenue) * 100 : 0}%` }} /></div><b>{rupiah(x.income)} • {x.count} booking</b></div>)}</div>
      <div className="card" style={{ marginTop: 16 }}><h3>Ekspor Data</h3><div className="actions">{Object.keys(exporters).map((k) => <button key={k} className="btn" onClick={() => { exporters[k](); toast('CSV diunduh'); }}>{k} CSV</button>)}</div></div>
    </>
  );
}

function LogsPage({ data }) {
  return (
    <div className="table-wrap"><table><thead><tr><th>Waktu</th><th>Admin</th><th>Aksi</th><th>Entitas</th><th>Detail</th></tr></thead>
      <tbody>{data.logs.map((l) => <tr key={l.id}><td>{dateId(l.created_at)}</td><td>{l.profiles?.full_name || l.profiles?.email || '-'}</td><td><Badge kind="blue">{l.action}</Badge></td><td>{l.entity}<div className="muted small">{l.entity_id || ''}</div></td><td><code className="small">{JSON.stringify(l.detail || {})}</code></td></tr>)}
        {!data.logs.length && <tr><td colSpan="5">Belum ada log admin.</td></tr>}</tbody></table></div>
  );
}

function SettingsPage({ profile, session, setPage, settings, reload, logAdmin, toast }) {
  const [taxPercent, setTaxPercent] = useState('0');
  const [feePercent, setFeePercent] = useState('0');
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    setTaxPercent(String(settings?.tax_percent ?? 0));
    setFeePercent(String(settings?.fee_percent ?? 0));
  }, [settings]);

  const parsePercent = (value) => {
    const parsed = Number(String(value).replace(',', '.'));
    if (!Number.isFinite(parsed) || parsed < 0 || parsed > 100) return null;
    return Math.round(parsed * 100) / 100;
  };

  const savePricing = async (e) => {
    e.preventDefault();
    const tax = parsePercent(taxPercent);
    const fee = parsePercent(feePercent);
    if (tax === null || fee === null) {
      toast('Pajak dan fee harus berupa angka antara 0 sampai 100 persen', true);
      return;
    }
    setSaving(true);
    const { error } = await supabase
      .from('app_settings')
      .upsert({ id: 1, tax_percent: tax, fee_percent: fee, updated_by: session.user.id, updated_at: new Date().toISOString() }, { onConflict: 'id' });
    setSaving(false);
    if (error) {
      toast(`Gagal menyimpan pengaturan: ${error.message}. Pastikan migration 202610080005_app_settings.sql sudah dijalankan.`, true);
      return;
    }
    await logAdmin('settings_pricing_update', 'app_settings', 1, { tax_percent: tax, fee_percent: fee });
    toast('Pengaturan pajak dan fee tersimpan. Booking baru akan memakai nilai ini.');
    await reload();
  };

  return (
    <div className="grid two">
      <div className="card"><h3>Pajak & Biaya Layanan</h3>
        <p className="hint">Default saat ini: <b>0%</b> (pajak dan fee nonaktif). Nilai yang disimpan di sini dibaca aplikasi Flutter untuk booking baru. Booking lama tidak berubah.</p>
        <form onSubmit={savePricing}>
          <label className="form-label">Pajak (%)
            <input type="number" min="0" max="100" step="0.01" value={taxPercent} onChange={(e) => setTaxPercent(e.target.value)} />
          </label>
          <label className="form-label">Biaya layanan / fee (%)
            <input type="number" min="0" max="100" step="0.01" value={feePercent} onChange={(e) => setFeePercent(e.target.value)} />
          </label>
          <button className="btn primary" disabled={saving}>{saving ? 'Menyimpan...' : 'Simpan Pengaturan'}</button>
        </form>
        {!settings && <p className="hint">Tabel pengaturan belum terbaca. Jalankan migration <code>202610080005_app_settings.sql</code> di Supabase SQL Editor.</p>}
      </div>
      <div className="card"><h3>Koneksi Supabase</h3>
        <dl className="kv"><dt>Project URL</dt><dd>{SUPABASE_URL}</dd><dt>Admin Login</dt><dd>{profile?.email || session.user.email}</dd><dt>Role</dt><dd><Badge kind="blue">{profile?.role || '-'}</Badge></dd></dl>
        <p className="hint">Keamanan diatur oleh Supabase RLS. Hanya akun <b>profiles.role = 'admin'</b> yang bisa masuk panel ini.</p></div>
      <div className="card"><h3>Jadikan Akun Admin</h3><p>Jalankan SQL ini di Supabase SQL Editor setelah akun terdaftar:</p>
        <pre style={{ whiteSpace: 'pre-wrap', background: '#0f172a', color: '#fff', padding: 14, borderRadius: 12 }}>update public.profiles{'\n'}set role = 'admin'{'\n'}where email = 'email-kamu@contoh.com';</pre>
        <p className="hint">Berikan role admin hanya ke pengelola A&A Transport.</p></div>
      <div className="card"><h3>Pembayaran SakuRupiah</h3><p>Channel aktif: QRIS, QRISC, BCA VA, BRI VA, BSI VA, BNC VA, Danamon VA, GoPay, ShopeePay, Alfamart, Indomaret.</p>
        <p className="hint">API ID/API KEY bersifat rahasia dan diatur sebagai Supabase Edge Function secrets, bukan di panel ini.</p>
        <button className="btn" onClick={() => setPage('payments')}>Lihat Pembayaran</button></div>
      <div className="card"><h3>Integrasi Aplikasi</h3><p>Perubahan mobil, harga, status booking, dan review di panel ini langsung terbaca di aplikasi Flutter karena memakai database Supabase yang sama.</p>
        <div className="actions"><button className="btn" onClick={() => setPage('cars')}>Kelola Mobil</button><button className="btn" onClick={() => setPage('bookings')}>Kelola Booking</button></div></div>
    </div>
  );
}

export default function App() {
  const [session, setSession] = useState(null);
  const [profile, setProfile] = useState(null);
  const [checking, setChecking] = useState(true);
  const [page, setPage] = useState('dashboard');
  const [search, setSearch] = useState('');
  const [toastMsg, setToastMsg] = useState(null);
  const [modal, setModal] = useState(null);
  const [data, setData] = useState({ cars: [], features: [], bookings: [], payments: [], customers: [], reviews: [], logs: [], settings: null });
  const [bookingStatus, setBookingStatus] = useState('');
  const [paymentStatus, setPaymentStatus] = useState('');
  const [sidebarOpen, setSidebarOpen] = useState(false);

  const toast = useCallback((msg, isError = false) => {
    setToastMsg({ msg, isError });
    setTimeout(() => setToastMsg(null), 4200);
  }, []);

  const logAdmin = useCallback(async (action, entity, entityId, detail = {}) => {
    if (!session?.user) return;
    try {
      await supabase.from('admin_logs').insert({ admin_id: session.user.id, action, entity, entity_id: entityId ? String(entityId) : null, detail });
    } catch { /* best-effort */ }
  }, [session]);

  const loadAll = useCallback(async () => {
    const [cars, features, bookings, payments, customers, reviews, logs, settings] = await Promise.all([
      supabase.from('cars').select('*, car_photos(url, sort_order), car_features(feature_id, features(name))').order('created_at', { ascending: false }),
      supabase.from('features').select('*').order('name'),
      supabase.from('bookings').select('*, cars(name, image_url, location)').order('created_at', { ascending: false }).limit(500),
      supabase.from('payments').select('*, bookings(cars(name), customer_name)').order('created_at', { ascending: false }).limit(500),
      supabase.from('profiles').select('*').order('created_at', { ascending: false }).limit(500),
      supabase.from('reviews').select('*, cars(name), profiles(full_name, email)').order('created_at', { ascending: false }).limit(500),
      supabase.from('admin_logs').select('*, profiles(full_name, email)').order('created_at', { ascending: false }).limit(100),
      supabase.from('app_settings').select('*').eq('id', 1).maybeSingle(),
    ]);
    const loadErrors = [cars, features, bookings, payments, customers, reviews, logs]
      .filter((result) => result.error)
      .map((result) => result.error.message);
    if (loadErrors.length) toast(`Sebagian data gagal dimuat: ${loadErrors[0]}`, true);
    setData({
      cars: cars.data || [], features: features.data || [], bookings: bookings.data || [],
      payments: payments.data || [], customers: customers.data || [], reviews: reviews.data || [], logs: logs.data || [],
      settings: settings.error ? null : settings.data,
    });
  }, []);

  const verifyAdmin = useCallback(async (sess) => {
    if (!sess) { setSession(null); setProfile(null); setChecking(false); return; }
    const { data: prof } = await supabase.from('profiles').select('*').eq('id', sess.user.id).single();
    if (!prof || prof.role !== 'admin') {
      await supabase.auth.signOut();
      setSession(null); setProfile(null); setChecking(false);
      return;
    }
    setSession(sess); setProfile(prof); setChecking(false);
    await loadAll();
  }, [loadAll]);

  useEffect(() => {
    supabase.auth.getSession().then(({ data: d }) => verifyAdmin(d.session));
    const { data: sub } = supabase.auth.onAuthStateChange((_e, sess) => {
      if (!sess) { setSession(null); setProfile(null); setChecking(false); }
    });
    return () => sub.subscription.unsubscribe();
  }, [verifyAdmin]);

  if (checking) return <div className="login-wrap"><p className="muted">Memuat admin panel...</p></div>;
  if (!session) return <LoginPage onLoggedIn={verifyAdmin} />;

  const pageMeta = NAV.find((n) => n[0] === page);

  return (
    <div className="layout">
      <aside className={`sidebar ${sidebarOpen ? 'open' : ''}`}>
        <div className="brand"><span className="brand-badge"><img src="/favicon.svg" alt="A&A Transport" /></span><div><h1>A&A Transport</h1><p>Admin Panel</p></div></div>
        <nav>
          {NAV.map(([key, label]) => (
            <button key={key} className={page === key ? 'active' : ''} onClick={() => { setPage(key); setSidebarOpen(false); }}>{label}</button>
          ))}
        </nav>
        <div className="sidebar-foot">
          <div className="admin-id">{profile?.full_name || 'Admin'} • {session.user.email}</div>
          <button className="btn danger full" onClick={async () => { await supabase.auth.signOut(); location.reload(); }}>Logout</button>
        </div>
      </aside>

      <main className="main">
        <header className="topbar">
          <button className="btn ghost only-mobile" onClick={() => setSidebarOpen(!sidebarOpen)}>☰</button>
          <div><h2>{pageMeta[1].replace(/^\S+\s/, '')}</h2><p>{pageMeta[2]}</p></div>
          <div className="top-actions">
            <input value={search} onChange={(e) => setSearch(e.target.value)} placeholder="Cari mobil, booking, pelanggan..." />
            <button className="btn" onClick={async () => { await loadAll(); toast('Data diperbarui'); }}>↻ Muat Ulang</button>
          </div>
        </header>
        {toastMsg && <div className={`toast ${toastMsg.isError ? 'error' : ''}`}>{toastMsg.msg}</div>}

        {page === 'dashboard' && <Dashboard data={data} />}
        {page === 'cars' && <CarsPage data={data} search={search} reload={loadAll} logAdmin={logAdmin} toast={toast} setModal={setModal} />}
        {page === 'bookings' && <BookingsPage data={data} search={search} reload={loadAll} logAdmin={logAdmin} toast={toast} setModal={setModal} bookingStatus={bookingStatus} setBookingStatus={setBookingStatus} paymentStatus={paymentStatus} setPaymentStatus={setPaymentStatus} />}
        {page === 'calendar' && <CalendarPage data={data} setModal={setModal} reload={loadAll} toast={toast} />}
        {page === 'payments' && <PaymentsPage data={data} reload={loadAll} logAdmin={logAdmin} toast={toast} />}
        {page === 'customers' && <CustomersPage data={data} search={search} reload={loadAll} logAdmin={logAdmin} toast={toast} setModal={setModal} currentUserId={session.user.id} />}
        {page === 'reviews' && <ReviewsPage data={data} reload={loadAll} logAdmin={logAdmin} toast={toast} />}
        {page === 'reports' && <ReportsPage data={data} toast={toast} />}
        {page === 'logs' && <LogsPage data={data} />}
        {page === 'settings' && <SettingsPage profile={profile} session={session} setPage={setPage} settings={data.settings} reload={loadAll} logAdmin={logAdmin} toast={toast} />}
      </main>

      {modal && (
        <div className="modal-backdrop" onClick={(e) => e.target.className === 'modal-backdrop' && setModal(null)}>
          <div className="modal">
            <div className="modal-head"><h3>{modal.title}</h3><button className="btn ghost" onClick={() => setModal(null)}>✕</button></div>
            {modal.body}
          </div>
        </div>
      )}
    </div>
  );
}
