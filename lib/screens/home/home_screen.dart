import 'package:flutter/material.dart';
import '../../models/car.dart';
import '../../services/app_services.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common_widgets.dart';
import 'car_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _search = TextEditingController();
  late Future<List<Car>> _future;
  Map<String, dynamic>? _profile;
  DateTime _pickupDate = DateTime.now().add(const Duration(days: 7));
  DateTime _returnDate = DateTime.now().add(const Duration(days: 10));
  int _passengers = 1;
  int _units = 1;

  @override
  void initState() {
    super.initState();
    _future = CarService.fetchCars();
    ProfileService.fetchProfile().then((p) {
      if (mounted) setState(() => _profile = p);
    }).catchError((_) {
      // The greeting can fall back to a generic name; the car catalogue has
      // its own visible error/retry state.
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() => _future = CarService.fetchCars(query: _search.text));
  }

  Future<void> _pickDates() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: _pickupDate, end: _returnDate),
    );
    if (picked != null) {
      setState(() {
        _pickupDate = picked.start;
        _returnDate = picked.end;
      });
    }
  }

  Future<void> _pickCount({
    required String title,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onSelected,
  }) async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(title: Text(title)),
            for (var i = min; i <= max; i++)
              ListTile(
                title: Text('$i'),
                trailing: i == value ? const Icon(Icons.check) : null,
                onTap: () => Navigator.pop(context, i),
              ),
          ],
        ),
      ),
    );
    if (selected != null) onSelected(selected);
  }

  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: FutureBuilder<List<Booking>>(
          future: BookingService.fetchBookings(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(height: 180, child: LoadingView());
            }
            if (snapshot.hasError) {
              return const SizedBox(
                  height: 180,
                  child: ErrorView(
                      message: 'Notifikasi belum bisa dimuat. Coba lagi nanti.'));
            }
            final relevant = (snapshot.data ?? [])
                .where((b) => b.tabStatus == 'upcoming')
                .take(5)
                .toList();
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Notifikasi',
                    style:
                        TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (relevant.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text('Belum ada pengingat booking atau pembayaran.',
                        style: TextStyle(color: AppColors.textGrey)),
                  )
                else
                  ...relevant.map((b) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                            b.isPaid
                                ? Icons.event_available_outlined
                                : Icons.payment_outlined,
                            color: AppColors.primary),
                        title: Text(b.isPaid
                            ? 'Booking ${b.car.name} terkonfirmasi'
                            : 'Pembayaran ${b.car.name} masih pending'),
                        subtitle: Text(
                            '${formatDateId(b.pickupDate)} - ${formatDateId(b.returnDate)}'),
                      )),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = (_profile?['full_name'] ?? 'Traveler').toString();
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _reload(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(radius: 22, child: Icon(Icons.person)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Halo, $name',
                              style: const TextStyle(
                                  color: AppColors.textGrey, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          const Row(children: [
                            Text('Find Car Nearby',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Icon(Icons.keyboard_arrow_down, size: 18),
                          ]),
                        ],
                      ),
                    ),
                    IconButton(
                        onPressed: _showNotifications,
                        icon: const Icon(Icons.notifications_outlined)),
                  ],
                ),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 14)
                      ]),
                  child: Column(
                    children: [
                      AppTextField(
                          hint: 'Cari car atau kota...',
                          icon: Icons.search,
                          controller: _search,
                          onSubmitted: (_) => _reload()),
                      const SizedBox(height: 14),
                      Row(children: [
                        Expanded(
                            child: GestureDetector(
                                onTap: _pickDates,
                                child: _infoChip(Icons.calendar_month_outlined,
                                    formatDateId(_pickupDate)))),
                        const SizedBox(width: 12),
                        Expanded(
                            child: GestureDetector(
                                onTap: _pickDates,
                                child: _infoChip(Icons.calendar_month_outlined,
                                    formatDateId(_returnDate)))),
                      ]),
                      const SizedBox(height: 14),
                      Row(children: [
                        Expanded(
                            child: GestureDetector(
                                onTap: () => _pickCount(
                                      title: 'Jumlah penumpang',
                                      value: _passengers,
                                      min: 1,
                                      max: 14,
                                      onSelected: (v) =>
                                          setState(() => _passengers = v),
                                    ),
                                child: _infoChip(Icons.person_outline,
                                    '$_passengers Penumpang'))),
                        const SizedBox(width: 12),
                        Expanded(
                            child: GestureDetector(
                                onTap: () => _pickCount(
                                      title: 'Jumlah mobil',
                                      value: _units,
                                      min: 1,
                                      max: 5,
                                      onSelected: (v) =>
                                          setState(() => _units = v),
                                    ),
                                child: _infoChip(
                                    Icons.directions_car_outlined,
                                    '$_units Mobil'))),
                      ]),
                      const SizedBox(height: 18),
                      PrimaryButton(text: 'Find Car', onPressed: _reload),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                FutureBuilder<List<Car>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const LoadingView();
                    }
                    if (snapshot.hasError) {
                      return ErrorView(
                          message:
                              'Gagal memuat car. Pastikan tabel Supabase sudah dibuat (lihat BACKEND_SETUP.md).',
                          onRetry: _reload);
                    }
                    final cars = snapshot.data ?? [];
                    if (cars.isEmpty) {
                      return const ErrorView(
                          message:
                              'Belum ada car. Tambahkan data car di Supabase.');
                    }
                    final popular = cars.take(3).toList();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(title: 'Popular Car'),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 225,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: popular.length,
                            itemBuilder: (_, i) => CarCard(
                              car: popular[i],
                              onTap: () async {
                                await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => CarDetailsScreen(
                                              car: popular[i],
                                              initialPickupDate: _pickupDate,
                                              initialReturnDate: _returnDate,
                                              initialPassengers: _passengers,
                                              initialUnits: _units,
                                            )));
                                _reload();
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const SectionHeader(title: 'Pilihan Mobil Untukmu'),
                        const SizedBox(height: 14),
                        ...cars.map((h) => CarCard(
                              car: h,
                              horizontal: true,
                              onTap: () async {
                                await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => CarDetailsScreen(
                                              car: h,
                                              initialPickupDate: _pickupDate,
                                              initialReturnDate: _returnDate,
                                              initialPassengers: _passengers,
                                              initialUnits: _units,
                                            )));
                                _reload();
                              },
                            )),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border)),
      child: Row(children: [
        Icon(icon, size: 19, color: AppColors.textGrey),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13)))
      ]),
    );
  }
}
