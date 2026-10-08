/* A&A Transport Admin Panel — Supabase (publishable key + RLS admin policies) */
const config = window.AA_CONFIG || {};
const supabaseClient = window.supabase.createClient(config.SUPABASE_URL, config.SUPABASE_PUBLISHABLE_KEY);

const state = {
  user: null,
  profile: null,
  page: 'dashboard',
  cars: [],
  features: [],
  bookings: [],
  payments: [],
  customers: [],
  reviews: [],
  logs: [],
  filters: {},
};

const $ = (sel) => document.querySelector(sel);
const $$ = (sel) => [...document.querySelectorAll(sel)];
const rupiah = (n) => 'Rp' + Math.round(Number(n || 0)).toString().replace(/\B(?=(\d{3})+(?!\d))/g, '.');
const esc = (s) => String(s ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const dateId = (d) => {
  if (!d) return '-';
  const x = new Date(d);
  if (Number.isNaN(x.getTime())) return esc(d);
  return x.toLocaleDateString('id-ID', { day: 'numeric', month: 'short', year: 'numeric' });
};
const badge = (text, kind = 'grey') => `<span class="badge ${kind}">${esc(text)}</span>`;
const paymentBadge = (s) => s === 'berhasil' ? badge('Berhasil', 'green') : s === 'expired' ? badge('Kedaluwarsa', 'red') : badge('Pending', 'orange');
const bookingBadge = (s) => ({ confirmed: badge('Terkonfirmasi', 'green'), completed: badge('Selesai', 'blue'), cancelled: badge('Dibatalkan', 'red'), expired: badge('Kedaluwarsa', 'red'), pending_payment: badge('Menunggu Pembayaran', 'orange') }[s] || badge(s, 'grey'));

function toast(msg, isError = false) {
  const el = $('#toast');
  el.textContent = msg;
  el.className = 'toast' + (isError ? ' error' : '');
  el.classList.remove('hidden');
  setTimeout(() => el.classList.add('hidden'), 4200);
}
function openModal(title, html) {
  $('#modalTitle').textContent = title;
  $('#modalBody').innerHTML = html;
  $('#modalBackdrop').classList.remove('hidden');
}
function closeModal() { $('#modalBackdrop').classList.add('hidden'); }
async function logAdmin(action, entity, entityId, detail = {}) {
  try {
    await supabaseClient.from('admin_logs').insert({ admin_id: state.user.id, action, entity, entity_id: entityId ? String(entityId) : null, detail });
  } catch (_) { /* logging is best-effort */ }
}

async function requireAdmin() {
  const { data } = await supabaseClient.auth.getSession();
  if (!data.session) return false;
  state.user = data.session.user;
  const { data: profile, error } = await supabaseClient.from('profiles').select('*').eq('id', state.user.id).single();
  if (error || !profile || profile.role !== 'admin') {
    await supabaseClient.auth.signOut();
    state.user = null;
    return false;
  }
  state.profile = profile;
  return true;
}

async function loadAll() {
  const [cars, features, bookings, payments, customers, reviews, logs] = await Promise.all([
    supabaseClient.from('cars').select('*, car_photos(url, sort_order), car_features(feature_id, features(name))').order('created_at', { ascending: false }),
    supabaseClient.from('features').select('*').order('name'),
    supabaseClient.from('bookings').select('*, cars(name, image_url, location), profiles:profiles!bookings_user_id_fkey(full_name, email)').order('created_at', { ascending: false }).limit(500),
    supabaseClient.from('payments').select('*, bookings(cars(name), customer_name)').order('created_at', { ascending: false }).limit(500),
    supabaseClient.from('profiles').select('*').order('created_at', { ascending: false }).limit(500),
    supabaseClient.from('reviews').select('*, cars(name), profiles(full_name, email)').order('created_at', { ascending: false }).limit(500),
    supabaseClient.from('admin_logs').select('*, profiles(full_name, email)').order('created_at', { ascending: false }).limit(100),
  ]);
  // Booking->profiles relation name can differ; fall back to customer fields if embed fails.
  state.cars = cars.data || [];
  state.features = features.data || [];
  state.bookings = bookings.error ? (await supabaseClient.from('bookings').select('*, cars(name, image_url, location)').order('created_at', { ascending: false }).limit(500)).data || [] : bookings.data || [];
  state.payments = payments.data || [];
  state.customers = customers.data || [];
  state.reviews = reviews.data || [];
  state.logs = logs.data || [];
}

function setPage(page) {
  state.page = page;
  $$('#sideNav button').forEach((b) => b.classList.toggle('active', b.dataset.page === page));
  const titles = {
    dashboard: ['Dashboard', 'Ringkasan bisnis A&A Transport'],
    cars: ['Mobil', 'Kelola armada, harga, foto, dan fitur mobil'],
    bookings: ['Booking', 'Kelola rental pelanggan dan status perjalanan'],
    calendar: ['Kalender Rental', 'Jadwal pengambilan mobil berdasarkan tanggal'],
    payments: ['Pembayaran', 'Transaksi SakuRupiah dan pendapatan'],
    customers: ['Pelanggan', 'Akun pelanggan aplikasi A&A Transport'],
    reviews: ['Review', 'Ulasan pelanggan untuk setiap mobil'],
    reports: ['Laporan', 'Ekspor CSV dan ringkasan performa'],
    logs: ['Log Admin', 'Riwayat aktivitas admin panel'],
    settings: ['Pengaturan', 'Konfigurasi Supabase, SakuRupiah, dan hak akses'],
  };
  $('#pageTitle').textContent = titles[page][0];
  $('#pageSubtitle').textContent = titles[page][1];
  render();
}

function render() {
  const pages = { dashboard: renderDashboard, cars: renderCars, bookings: renderBookings, calendar: renderCalendar, payments: renderPayments, customers: renderCustomers, reviews: renderReviews, reports: renderReports, logs: renderLogs, settings: renderSettings };
  (pages[state.page] || renderDashboard)();
}

function statCard(label, value, sub) { return `<div class="card stat"><div class="label">${label}</div><div class="value">${value}</div><div class="sub">${sub || ''}</div></div>`; }

function renderDashboard() {
  const paidBookings = state.bookings.filter((b) => b.payment_status === 'berhasil');
  const revenue = paidBookings.reduce((a, b) => a + Number(b.total || 0), 0);
  const pending = state.bookings.filter((b) => b.status === 'pending_payment');
  const upcoming = state.bookings.filter((b) => b.status === 'confirmed' && new Date(b.pickup_date) >= new Date(new Date().toDateString()));
  const last7 = [...Array(7)].map((_, i) => {
    const d = new Date(); d.setDate(d.getDate() - (6 - i));
    const key = d.toISOString().slice(0, 10);
    const sum = state.payments.filter((p) => p.status === 'berhasil' && String(p.created_at).slice(0, 10) === key).reduce((a, p) => a + Number(p.amount || 0), 0);
    return { label: d.toLocaleDateString('id-ID', { weekday: 'short' }), sum };
  });
  const max = Math.max(...last7.map((x) => x.sum), 1);
  const popular = [...state.cars].sort((a, b) => Number(b.rating || 0) - Number(a.rating || 0)).slice(0, 5);
  $('#pageContent').innerHTML = `
    <div class="grid stats">
      ${statCard('Total Pendapatan', rupiah(revenue), `${paidBookings.length} pembayaran berhasil`)}
      ${statCard('Total Booking', state.bookings.length, `${pending.length} menunggu pembayaran`)}
      ${statCard('Mobil Aktif', state.cars.filter((c) => c.is_active).length, `${state.cars.length} total armada`)}
      ${statCard('Pelanggan', state.customers.length, `${upcoming.length} rental akan datang`)}
    </div>
    <div class="grid two" style="margin-top:16px">
      <div class="card"><h3>Pendapatan 7 Hari Terakhir</h3>${last7.map((x) => `<div class="bar-row"><span>${x.label}</span><div class="bar"><i style="width:${(x.sum / max) * 100}%"></i></div><b>${rupiah(x.sum)}</b></div>`).join('')}</div>
      <div class="card"><h3>Mobil Rating Tertinggi</h3>${popular.map((c) => `<div class="bar-row"><span>${esc(c.name)}</span><div class="bar"><i style="width:${Number(c.rating || 0) * 20}%"></i></div><b>⭐ ${c.rating || 0} (${c.review_count || 0})</b></div>`).join('') || '<p>Belum ada mobil.</p>'}</div>
    </div>
    <div class="card" style="margin-top:16px"><h3>Booking Terbaru</h3>${bookingTable(state.bookings.slice(0, 8), true)}</div>`;
}

function carRows(list) {
  return list.map((c) => `<tr>
    <td><img class="thumb" src="${esc(c.image_url || '')}" onerror="this.style.display='none'"/></td>
    <td><b>${esc(c.name)}</b><div class="muted small">${esc(c.car_type)} • ${c.seats} kursi • ${esc(c.transmission)}</div></td>
    <td>${esc(c.location)}</td><td><b>${rupiah(c.price_per_day)}</b>/hari</td><td>⭐ ${c.rating || 0} (${c.review_count || 0})</td>
    <td>${c.is_active ? badge('Aktif', 'green') : badge('Nonaktif', 'grey')}</td>
    <td><div class="actions"><button class="btn small" onclick="editCar('${c.id}')">Edit</button><button class="btn small" onclick="managePhotos('${c.id}')">Foto</button><button class="btn small" onclick="toggleCarActive('${c.id}', ${!c.is_active})">${c.is_active ? 'Nonaktifkan' : 'Aktifkan'}</button></div></td></tr>`).join('');
}
function renderCars() {
  const q = ($('#globalSearch').value || '').toLowerCase();
  const list = state.cars.filter((c) => !q || c.name.toLowerCase().includes(q) || c.location.toLowerCase().includes(q));
  $('#pageContent').innerHTML = `
    <div class="toolbar"><button class="btn primary" onclick="editCar()">+ Tambah Mobil</button><span class="spacer"></span><span class="muted">${list.length} mobil</span></div>
    <div class="table-wrap"><table><thead><tr><th>Foto</th><th>Mobil</th><th>Lokasi</th><th>Harga</th><th>Rating</th><th>Status</th><th>Aksi</th></tr></thead><tbody>${carRows(list) || '<tr><td colspan="7">Belum ada mobil.</td></tr>'}</tbody></table></div>`;
}
window.toggleCarActive = async (id, active) => {
  const { error } = await supabaseClient.from('cars').update({ is_active: active }).eq('id', id);
  if (error) return toast(error.message, true);
  await logAdmin(active ? 'car_activate' : 'car_deactivate', 'cars', id);
  toast('Status mobil diperbarui'); await loadAll(); render();
};
window.editCar = (id) => {
  const c = state.cars.find((x) => x.id === id) || {};
  const selected = new Set((c.car_features || []).map((x) => x.feature_id));
  openModal(id ? 'Edit Mobil' : 'Tambah Mobil', `
    <form id="carForm">
      <div class="form-grid">
        <label>Nama mobil<input name="name" required value="${esc(c.name || '')}" placeholder="Toyota Avanza"/></label>
        <label>Lokasi / kota penjemputan<input name="location" required value="${esc(c.location || 'Makassar')}"/></label>
        <label>Harga per hari (Rp)<input name="price_per_day" type="number" min="0" required value="${c.price_per_day || 350000}"/></label>
        <label>URL foto utama<input name="image_url" value="${esc(c.image_url || '')}" placeholder="https://..."/></label>
        <label>Tipe mobil<select name="car_type">${['MPV', 'SUV', 'Van', 'Premium', 'City Car', 'Pickup'].map((t) => `<option ${c.car_type === t ? 'selected' : ''}>${t}</option>`).join('')}</select></label>
        <label>Jumlah kursi<input name="seats" type="number" min="1" value="${c.seats || 7}"/></label>
        <label>Transmisi<select name="transmission">${['Automatic', 'Manual'].map((t) => `<option ${c.transmission === t ? 'selected' : ''}>${t}</option>`).join('')}</select></label>
        <label>Bahan bakar<select name="fuel_type">${['Bensin', 'Diesel', 'Hybrid', 'Listrik'].map((t) => `<option ${c.fuel_type === t ? 'selected' : ''}>${t}</option>`).join('')}</select></label>
        <label>Kapasitas bagasi<input name="baggage" type="number" min="0" value="${c.baggage || 2}"/></label>
        <label>Status<select name="is_active"><option value="true" ${c.is_active !== false ? 'selected' : ''}>Aktif</option><option value="false" ${c.is_active === false ? 'selected' : ''}>Nonaktif</option></select></label>
        <label class="wide">Deskripsi<textarea name="description" rows="4">${esc(c.description || '')}</textarea></label>
      </div>
      <h4>Fitur mobil</h4><div class="checks">${state.features.map((f) => `<label><input type="checkbox" name="feature" value="${f.id}" ${selected.has(f.id) ? 'checked' : ''}/> ${esc(f.name)}</label>`).join('')}</div>
      <div style="display:flex;gap:10px;margin-top:20px"><button class="btn primary" type="submit">Simpan Mobil</button>${id ? `<button class="btn danger" type="button" onclick="deleteCar('${id}')">Hapus Permanen</button>` : ''}</div>
    </form>`);
  $('#carForm').onsubmit = async (e) => {
    e.preventDefault();
    const fd = new FormData(e.target);
    const payload = { name: fd.get('name'), location: fd.get('location'), price_per_day: Number(fd.get('price_per_day')), image_url: fd.get('image_url'), car_type: fd.get('car_type'), seats: Number(fd.get('seats')), transmission: fd.get('transmission'), fuel_type: fd.get('fuel_type'), baggage: Number(fd.get('baggage')), is_active: fd.get('is_active') === 'true', description: fd.get('description') };
    const res = id ? await supabaseClient.from('cars').update(payload).eq('id', id).select().single() : await supabaseClient.from('cars').insert(payload).select().single();
    if (res.error) return toast(res.error.message, true);
    const carId = res.data.id;
    await supabaseClient.from('car_features').delete().eq('car_id', carId);
    const featureIds = fd.getAll('feature');
    if (featureIds.length) await supabaseClient.from('car_features').insert(featureIds.map((feature_id) => ({ car_id: carId, feature_id })));
    await logAdmin(id ? 'car_update' : 'car_create', 'cars', carId, payload);
    closeModal(); toast('Mobil tersimpan dan langsung tampil di aplikasi'); await loadAll(); render();
  };
};
window.deleteCar = async (id) => {
  if (!confirm('Hapus mobil ini permanen? Booking lama bisa gagal dihapus karena relasi data. Lebih aman nonaktifkan mobil. Tetap hapus?')) return;
  const { error } = await supabaseClient.from('cars').delete().eq('id', id);
  if (error) return toast(error.message, true);
  await logAdmin('car_delete', 'cars', id); closeModal(); await loadAll(); render();
};
window.managePhotos = (id) => {
  const c = state.cars.find((x) => x.id === id);
  const photos = [...(c.car_photos || [])].sort((a, b) => (a.sort_order || 0) - (b.sort_order || 0));
  openModal('Foto ' + c.name, `
    <div>${photos.map((p, i) => `<div class="bar-row"><span>Foto ${i + 1}</span><input value="${esc(p.url)}" readonly/><button class="btn danger small" onclick="deletePhoto('${id}','${esc(p.url)}')">Hapus</button></div>`).join('') || '<p class="muted">Belum ada foto tambahan.</p>'}</div>
    <form id="photoForm"><label>Tambah URL foto<input name="url" required placeholder="https://images.unsplash.com/..."/></label><button class="btn primary">Tambah Foto</button></form>
    <p class="hint">Foto utama diatur dari form Edit Mobil. Foto tambahan di sini tampil sebagai galeri di aplikasi.</p>`);
  $('#photoForm').onsubmit = async (e) => {
    e.preventDefault();
    const url = new FormData(e.target).get('url');
    const { error } = await supabaseClient.from('car_photos').insert({ car_id: id, url, sort_order: photos.length + 1 });
    if (error) return toast(error.message, true);
    await logAdmin('car_photo_add', 'cars', id, { url }); await loadAll(); closeModal(); render();
  };
};
window.deletePhoto = async (carId, url) => {
  const { error } = await supabaseClient.from('car_photos').delete().eq('car_id', carId).eq('url', url);
  if (error) return toast(error.message, true);
  await logAdmin('car_photo_delete', 'cars', carId, { url }); await loadAll(); closeModal(); render();
};

function bookingTable(list, compact = false) {
  return `<div class="table-wrap"><table><thead><tr><th>Booking</th><th>Mobil</th><th>Penyewa</th><th>Ambil</th><th>Total</th><th>Pembayaran</th><th>Status</th>${compact ? '' : '<th>Aksi</th>'}</tr></thead><tbody>${list.map((b) => `<tr>
    <td><b>${esc(String(b.id).slice(0, 8).toUpperCase())}</b><div class="muted small">${dateId(b.created_at)}</div></td>
    <td>${esc(b.cars?.name || '-')}</td><td>${esc(b.customer_name)}<div class="muted small">${esc(b.customer_phone)}</div></td>
    <td>${dateId(b.pickup_date)}<div class="muted small">s/d ${dateId(b.return_date)} (${b.days} hari)</div></td><td><b>${rupiah(b.total)}</b></td><td>${paymentBadge(b.payment_status)}</td><td>${bookingBadge(b.status)}</td>
    ${compact ? '' : `<td><div class="actions"><button class="btn small" onclick="bookingDetail('${b.id}')">Detail</button><button class="btn small" onclick="checkPayment('${b.id}')">Cek Bayar</button></div></td>`}</tr>`).join('') || '<tr><td colspan="8">Tidak ada booking.</td></tr>'}</tbody></table></div>`;
}
function renderBookings() {
  const q = ($('#globalSearch').value || '').toLowerCase();
  const status = state.filters.bookingStatus || '';
  const pay = state.filters.paymentStatus || '';
  const list = state.bookings.filter((b) => (!status || b.status === status) && (!pay || b.payment_status === pay) && (!q || b.customer_name.toLowerCase().includes(q) || (b.cars?.name || '').toLowerCase().includes(q) || b.id.toLowerCase().includes(q)));
  $('#pageContent').innerHTML = `
    <div class="toolbar"><select onchange="state.filters.bookingStatus=this.value;render()"><option value="">Semua status booking</option>${['pending_payment', 'confirmed', 'completed', 'cancelled', 'expired'].map((s) => `<option value="${s}" ${status === s ? 'selected' : ''}>${s}</option>`).join('')}</select>
    <select onchange="state.filters.paymentStatus=this.value;render()"><option value="">Semua pembayaran</option>${['pending', 'berhasil', 'expired', 'failed'].map((s) => `<option value="${s}" ${pay === s ? 'selected' : ''}>${s}</option>`).join('')}</select>
    <button class="btn" onclick="exportCsv('bookings')">Ekspor CSV</button></div>${bookingTable(list)}`;
}
window.bookingDetail = (id) => {
  const b = state.bookings.find((x) => x.id === id);
  openModal('Detail Booking', `
    <dl class="kv"><dt>ID Booking</dt><dd>${esc(b.id)}</dd><dt>Mobil</dt><dd>${esc(b.cars?.name || '-')}</dd><dt>Penyewa</dt><dd>${esc(b.customer_name)}</dd><dt>Email</dt><dd>${esc(b.customer_email)}</dd><dt>Telepon</dt><dd>${esc(b.customer_phone)}</dd><dt>Tanggal</dt><dd>${dateId(b.pickup_date)} s/d ${dateId(b.return_date)} (${b.days} hari)</dd><dt>Layanan</dt><dd>${esc(b.service_type)} • ${b.units} mobil • ${b.passengers} penumpang</dd><dt>Subtotal</dt><dd>${rupiah(b.subtotal)}</dd><dt>Pajak</dt><dd>${rupiah(b.tax)}</dd><dt>Total</dt><dd>${rupiah(b.total)}</dd><dt>Metode</dt><dd>${esc(b.payment_method_code || '-')} via SakuRupiah</dd><dt>Transaksi</dt><dd>${esc(b.sakurupiah_trx_id || '-')}</dd><dt>No. VA/Pembayaran</dt><dd>${esc(b.payment_no || '-')}</dd></dl>
    <h4>Ubah Status Booking</h4><div class="actions">${['pending_payment', 'confirmed', 'completed', 'cancelled', 'expired'].map((s) => `<button class="btn small" onclick="setBookingStatus('${b.id}','${s}')">${s}</button>`).join('')}</div>
    <div style="margin-top:16px" class="actions"><button class="btn primary" onclick="checkPayment('${b.id}')">Cek Status SakuRupiah</button>${b.checkout_url ? `<a class="btn" href="${esc(b.checkout_url)}" target="_blank">Buka Checkout</a>` : ''}</div>`);
};
window.setBookingStatus = async (id, status) => {
  const { error } = await supabaseClient.from('bookings').update({ status }).eq('id', id);
  if (error) return toast(error.message, true);
  await logAdmin('booking_status_update', 'bookings', id, { status }); toast('Status booking diperbarui'); closeModal(); await loadAll(); render();
};
window.checkPayment = async (id) => {
  toast('Mengecek status ke SakuRupiah...');
  const { data, error } = await supabaseClient.functions.invoke('check-payment', { body: { booking_id: id } });
  if (error) return toast(error.message, true);
  if (data?.error) return toast(data.error, true);
  await logAdmin('payment_check', 'bookings', id, data); toast('Status pembayaran: ' + (data.status || '-')); await loadAll(); render();
};

function renderCalendar() {
  const now = new Date(); const year = now.getFullYear(); const month = now.getMonth();
  const first = new Date(year, month, 1); const days = new Date(year, month + 1, 0).getDate();
  const cells = [];
  for (let d = 1; d <= days; d++) {
    const key = `${year}-${String(month + 1).padStart(2, '0')}-${String(d).padStart(2, '0')}`;
    const items = state.bookings.filter((b) => b.pickup_date === key && b.status !== 'cancelled');
    cells.push(`<div class="day"><div class="date">${d}</div>${items.map((b) => `<div class="item" onclick="bookingDetail('${b.id}')">🚗 ${esc(b.cars?.name || 'Mobil')}<br>${esc(b.customer_name)}</div>`).join('')}</div>`);
  }
  $('#pageContent').innerHTML = `<div class="card"><h3>${now.toLocaleDateString('id-ID', { month: 'long', year: 'numeric' })} — tanggal pengambilan mobil</h3><div class="calendar">${cells.join('')}</div></div>`;
}

function renderPayments() {
  const status = state.filters.paymentOnly || '';
  const list = state.payments.filter((p) => !status || p.status === status);
  const revenue = state.payments.filter((p) => p.status === 'berhasil').reduce((a, p) => a + Number(p.amount || 0), 0);
  $('#pageContent').innerHTML = `
    <div class="grid stats" style="margin-bottom:16px">${statCard('Pendapatan Berhasil', rupiah(revenue), 'Dari pembayaran SakuRupiah berstatus berhasil')}${statCard('Transaksi', state.payments.length, `${state.payments.filter((p) => p.status === 'pending').length} pending`)}</div>
    <div class="toolbar"><select onchange="state.filters.paymentOnly=this.value;render()"><option value="">Semua status</option>${['pending', 'berhasil', 'expired', 'failed'].map((s) => `<option ${status === s ? 'selected' : ''}>${s}</option>`).join('')}</select><button class="btn" onclick="exportCsv('payments')">Ekspor CSV</button></div>
    <div class="table-wrap"><table><thead><tr><th>Tanggal</th><th>Transaksi</th><th>Booking</th><th>Metode</th><th>Jumlah</th><th>Status</th><th>Aksi</th></tr></thead><tbody>${list.map((p) => `<tr><td>${dateId(p.created_at)}</td><td><b>${esc(p.trx_id || '-')}</b><div class="muted small">${esc(p.merchant_ref)}</div></td><td>${esc(p.bookings?.cars?.name || '-')}<div class="muted small">${esc(p.bookings?.customer_name || '')}</div></td><td>${esc(p.method_code)}</td><td><b>${rupiah(p.amount)}</b></td><td>${paymentBadge(p.status)}</td><td><button class="btn small" onclick="checkPayment('${p.booking_id}')">Cek Status</button></td></tr>`).join('') || '<tr><td colspan="7">Belum ada pembayaran.</td></tr>'}</tbody></table></div>`;
}

function renderCustomers() {
  const q = ($('#globalSearch').value || '').toLowerCase();
  const list = state.customers.filter((c) => !q || (c.full_name || '').toLowerCase().includes(q) || (c.email || '').toLowerCase().includes(q));
  $('#pageContent').innerHTML = `<div class="table-wrap"><table><thead><tr><th>Pelanggan</th><th>Kontak</th><th>Role</th><th>Booking</th><th>Bergabung</th><th>Aksi</th></tr></thead><tbody>${list.map((c) => {
    const count = state.bookings.filter((b) => b.user_id === c.id).length;
    return `<tr><td><b>${esc(c.full_name || 'Tanpa nama')}</b></td><td>${esc(c.email)}<div class="muted small">${esc(c.phone || '-')}</div></td><td>${c.role === 'admin' ? badge('Admin', 'blue') : badge('User', 'grey')}</td><td>${count}</td><td>${dateId(c.created_at)}</td><td><div class="actions"><button class="btn small" onclick="editCustomer('${c.id}')">Edit</button><button class="btn small" onclick="toggleRole('${c.id}','${c.role === 'admin' ? 'user' : 'admin'}')">${c.role === 'admin' ? 'Jadikan User' : 'Jadikan Admin'}</button></div></td></tr>`;
  }).join('') || '<tr><td colspan="6">Belum ada pelanggan.</td></tr>'}</tbody></table></div>`;
}
window.editCustomer = (id) => {
  const c = state.customers.find((x) => x.id === id);
  openModal('Edit Pelanggan', `<form id="customerForm"><label>Nama<input name="full_name" value="${esc(c.full_name || '')}"/></label><label>No. handphone<input name="phone" value="${esc(c.phone || '')}"/></label><label>URL avatar<input name="avatar_url" value="${esc(c.avatar_url || '')}"/></label><button class="btn primary">Simpan</button></form>`);
  $('#customerForm').onsubmit = async (e) => { e.preventDefault(); const fd = new FormData(e.target); const payload = { full_name: fd.get('full_name'), phone: fd.get('phone'), avatar_url: fd.get('avatar_url') || null }; const { error } = await supabaseClient.from('profiles').update(payload).eq('id', id); if (error) return toast(error.message, true); await logAdmin('customer_update', 'profiles', id, payload); closeModal(); await loadAll(); render(); };
};
window.toggleRole = async (id, role) => {
  if (id === state.user.id && role !== 'admin') return toast('Kamu tidak bisa menurunkan role akunmu sendiri.', true);
  if (!confirm(`Ubah role user ini menjadi ${role}?`)) return;
  const { error } = await supabaseClient.from('profiles').update({ role }).eq('id', id);
  if (error) return toast(error.message, true);
  await logAdmin('customer_role_update', 'profiles', id, { role }); await loadAll(); render();
};

function renderReviews() {
  $('#pageContent').innerHTML = `<div class="table-wrap"><table><thead><tr><th>Tanggal</th><th>Mobil</th><th>Pelanggan</th><th>Rating</th><th>Komentar</th><th>Aksi</th></tr></thead><tbody>${state.reviews.map((r) => `<tr><td>${dateId(r.created_at)}</td><td>${esc(r.cars?.name || '-')}</td><td>${esc(r.profiles?.full_name || 'Pengguna')}<div class="muted small">${esc(r.profiles?.email || '')}</div></td><td>${'⭐'.repeat(Number(r.rating || 0))}</td><td>${esc(r.comment)}</td><td><button class="btn danger small" onclick="deleteReview('${r.id}')">Hapus</button></td></tr>`).join('') || '<tr><td colspan="6">Belum ada review.</td></tr>'}</tbody></table></div>`;
}
window.deleteReview = async (id) => { if (!confirm('Hapus review ini?')) return; const { error } = await supabaseClient.from('reviews').delete().eq('id', id); if (error) return toast(error.message, true); await logAdmin('review_delete', 'reviews', id); await loadAll(); render(); };

function downloadCsv(filename, rows) {
  if (!rows.length) return toast('Tidak ada data untuk diekspor', true);
  const headers = Object.keys(rows[0]);
  const csv = [headers.join(','), ...rows.map((r) => headers.map((h) => `"${String(r[h] ?? '').replaceAll('"', '""')}"`).join(','))].join('\n');
  const a = document.createElement('a'); a.href = URL.createObjectURL(new Blob([csv], { type: 'text/csv' })); a.download = filename; a.click(); URL.revokeObjectURL(a.href);
}
window.exportCsv = (type) => {
  if (type === 'bookings') downloadCsv('bookings.csv', state.bookings.map((b) => ({ id: b.id, mobil: b.cars?.name || '', penyewa: b.customer_name, email: b.customer_email, telepon: b.customer_phone, ambil: b.pickup_date, kembali: b.return_date, hari: b.days, total: b.total, status: b.status, pembayaran: b.payment_status, metode: b.payment_method_code || '' })));
  if (type === 'payments') downloadCsv('payments.csv', state.payments.map((p) => ({ tanggal: p.created_at, trx_id: p.trx_id || '', merchant_ref: p.merchant_ref, metode: p.method_code, jumlah: p.amount, status: p.status, booking_id: p.booking_id })));
  if (type === 'cars') downloadCsv('cars.csv', state.cars.map((c) => ({ nama: c.name, lokasi: c.location, harga_per_hari: c.price_per_day, tipe: c.car_type, kursi: c.seats, transmisi: c.transmission, bahan_bakar: c.fuel_type, rating: c.rating, aktif: c.is_active })));
  if (type === 'customers') downloadCsv('customers.csv', state.customers.map((c) => ({ nama: c.full_name, email: c.email, telepon: c.phone || '', role: c.role, bergabung: c.created_at })));
};

function renderReports() {
  const revenue = state.bookings.filter((b) => b.payment_status === 'berhasil').reduce((a, b) => a + Number(b.total || 0), 0);
  const byCar = state.cars.map((c) => ({ car: c, bookings: state.bookings.filter((b) => b.car_id === c.id), income: state.bookings.filter((b) => b.car_id === c.id && b.payment_status === 'berhasil').reduce((a, b) => a + Number(b.total || 0), 0) })).sort((a, b) => b.income - a.income);
  $('#pageContent').innerHTML = `<div class="grid three">${statCard('Pendapatan', rupiah(revenue), 'Booking terbayar')}${statCard('Rata-rata Booking', rupiah(state.bookings.length ? revenue / Math.max(1, state.bookings.filter((b) => b.payment_status === 'berhasil').length) : 0), 'Per transaksi berhasil')}${statCard('Tingkat Selesai Bayar', `${state.bookings.length ? Math.round((state.bookings.filter((b) => b.payment_status === 'berhasil').length / state.bookings.length) * 100) : 0}%`, 'Dari semua booking')}</div>
  <div class="card" style="margin-top:16px"><h3>Performa Mobil</h3>${byCar.map((x) => `<div class="bar-row"><span>${esc(x.car.name)}</span><div class="bar"><i style="width:${revenue ? (x.income / revenue) * 100 : 0}%"></i></div><b>${rupiah(x.income)} • ${x.bookings.length} booking</b></div>`).join('')}</div>
  <div class="card" style="margin-top:16px"><h3>Ekspor Data</h3><div class="actions"><button class="btn" onclick="exportCsv('bookings')">Booking CSV</button><button class="btn" onclick="exportCsv('payments')">Pembayaran CSV</button><button class="btn" onclick="exportCsv('cars')">Mobil CSV</button><button class="btn" onclick="exportCsv('customers')">Pelanggan CSV</button></div></div>`;
}

function renderLogs() {
  $('#pageContent').innerHTML = `<div class="table-wrap"><table><thead><tr><th>Waktu</th><th>Admin</th><th>Aksi</th><th>Entitas</th><th>Detail</th></tr></thead><tbody>${state.logs.map((l) => `<tr><td>${dateId(l.created_at)}</td><td>${esc(l.profiles?.full_name || l.profiles?.email || '-')}</td><td>${badge(l.action, 'blue')}</td><td>${esc(l.entity)}<div class="muted small">${esc(l.entity_id || '')}</div></td><td><code class="small">${esc(JSON.stringify(l.detail || {}))}</code></td></tr>`).join('') || '<tr><td colspan="5">Belum ada log admin.</td></tr>'}</tbody></table></div>`;
}

function renderSettings() {
  $('#pageContent').innerHTML = `
  <div class="grid two">
    <div class="card"><h3>Koneksi Supabase</h3><dl class="kv"><dt>Project URL</dt><dd>${esc(config.SUPABASE_URL)}</dd><dt>Publishable Key</dt><dd>${esc(String(config.SUPABASE_PUBLISHABLE_KEY || '').slice(0, 18))}...</dd><dt>Admin Login</dt><dd>${esc(state.profile?.email || state.user.email)}</dd><dt>Role</dt><dd>${badge(state.profile?.role || '-', 'blue')}</dd></dl><p class="hint">Keamanan diatur oleh Supabase RLS. Hanya akun <b>profiles.role = 'admin'</b> yang bisa masuk panel ini dan mengelola data.</p></div>
    <div class="card"><h3>Jadikan Akun Admin</h3><p>Jalankan SQL ini di Supabase SQL Editor setelah akun terdaftar:</p><pre style="white-space:pre-wrap;background:#0f172a;color:#fff;padding:14px;border-radius:12px">update public.profiles
set role = 'admin'
where email = 'email-kamu@contoh.com';</pre><p class="hint">Jangan jadikan semua user admin. Berikan hanya ke pengelola A&A Transport.</p></div>
    <div class="card"><h3>Pembayaran SakuRupiah</h3><p>Channel aktif di aplikasi: QRIS, QRISC, BCA VA, BRI VA, BSI VA, BNC VA, Danamon VA, GoPay, ShopeePay, Alfamart, Indomaret.</p><p class="hint">API ID/API KEY tidak ditampilkan di panel ini karena rahasia. Atur melalui Supabase Edge Function secrets: <code>SAKURUPIAH_API_ID</code> dan <code>SAKURUPIAH_API_KEY</code>.</p><button class="btn" onclick="setPage('payments')">Lihat Pembayaran</button></div>
    <div class="card"><h3>Integrasi Aplikasi</h3><p>Perubahan mobil, harga, status booking, dan review di panel ini langsung terbaca di aplikasi Flutter karena memakai database Supabase yang sama.</p><div class="actions"><button class="btn" onclick="setPage('cars')">Kelola Mobil</button><button class="btn" onclick="setPage('bookings')">Kelola Booking</button></div></div>
  </div>`;
}

document.addEventListener('DOMContentLoaded', async () => {
  $('#modalClose').onclick = closeModal;
  $('#modalBackdrop').addEventListener('click', (e) => { if (e.target.id === 'modalBackdrop') closeModal(); });
  $('#menuBtn').onclick = () => document.querySelector('.sidebar').classList.toggle('open');
  $('#refreshBtn').onclick = async () => { await loadAll(); render(); toast('Data diperbarui'); };
  $('#globalSearch').addEventListener('input', () => { if (['cars', 'bookings', 'customers'].includes(state.page)) render(); });
  $$('#sideNav button').forEach((b) => b.onclick = () => setPage(b.dataset.page));
  $('#logoutBtn').onclick = async () => { await supabaseClient.auth.signOut(); location.reload(); };
  $('#loginForm').onsubmit = async (e) => {
    e.preventDefault();
    $('#loginError').textContent = '';
    const { error } = await supabaseClient.auth.signInWithPassword({ email: $('#loginEmail').value.trim(), password: $('#loginPassword').value });
    if (error) { $('#loginError').textContent = error.message; return; }
    const ok = await requireAdmin();
    if (!ok) { $('#loginError').textContent = 'Akun ini bukan admin. Jadikan role admin dulu lewat SQL Supabase.'; return; }
    await boot();
  };

  if (await requireAdmin()) await boot();
  else $('#loginView').classList.remove('hidden');
});

async function boot() {
  $('#loginView').classList.add('hidden');
  $('#appView').classList.remove('hidden');
  $('#adminIdentity').textContent = `${state.profile.full_name || 'Admin'} • ${state.user.email}`;
  await loadAll();
  setPage('dashboard');
}
