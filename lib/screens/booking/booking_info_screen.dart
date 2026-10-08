import 'package:flutter/material.dart';
import '../../models/car.dart';
import '../../services/app_services.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common_widgets.dart';
import 'customer_info_screen.dart';

class BookingInfoScreen extends StatefulWidget {
  final Car car;
  const BookingInfoScreen({super.key, required this.car});
  @override
  State<BookingInfoScreen> createState() => _BookingInfoScreenState();
}

class _BookingInfoScreenState extends State<BookingInfoScreen> {
  DateTime _pickupDate = DateTime.now().add(const Duration(days: 7));
  DateTime _returnDate = DateTime.now().add(const Duration(days: 10));
  int _passengers = 1;
  int _units = 1;
  String _serviceType = 'Dengan Sopir';
  PaymentChannel _channel = paymentChannels.first;

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

  void _pickChannel() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(22),
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Metode Pembayaran (SakuRupiah)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            const SizedBox(height: 8),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: paymentChannels
                    .map((c) => RadioListTile<String>(
                          value: c.code,
                          groupValue: _channel.code,
                          onChanged: (v) {
                            setState(() => _channel =
                                paymentChannels.firstWhere((e) => e.code == v));
                            Navigator.pop(context);
                          },
                          title: Text(c.name),
                          secondary: const Icon(Icons.payments_outlined,
                              color: AppColors.primary),
                        ))
                    .toList(),
              ),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const SavedPaymentMethodsScreen()));
              },
              icon: const Icon(Icons.bookmark_outline),
              label: const Text('Kelola metode tersimpan'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final days = _returnDate.difference(_pickupDate).inDays;
    return Scaffold(
      appBar: AppBar(
          title: const Text('Booking Info'), leading: const BackButton()),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CarCard(car: widget.car, horizontal: true),
            _dateField('Tanggal Ambil', formatDateId(_pickupDate)),
            _dateField('Tanggal Kembali', formatDateId(_returnDate)),
            Row(children: [
              Expanded(
                  child: _stepper('Penyewa', _passengers,
                      (v) => setState(() => _passengers = v))),
              const SizedBox(width: 12),
              Expanded(
                  child: _stepper(
                      'Mobil', _units, (v) => setState(() => _units = v))),
            ]),
            const SizedBox(height: 18),
            InputDecorator(
              decoration: const InputDecoration(
                  labelText: 'Jenis Layanan',
                  prefixIcon: Icon(Icons.meeting_room_outlined)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _serviceType,
                  isExpanded: true,
                  items: [
                    'Dengan Sopir',
                    'Lepas Kunci',
                    'Antar/Jemput Bandara',
                    'Sewa Harian + BBM'
                  ]
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _serviceType = v ?? _serviceType),
                ),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Metode Pembayaran',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('${_channel.name} via SakuRupiah'),
              trailing: const Icon(Icons.keyboard_arrow_right),
              onTap: _pickChannel,
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Text(
                  'Perkiraan total: ${formatRupiah(widget.car.price * (days < 1 ? 1 : days) * _units)} untuk ${days < 1 ? 1 : days} hari x $_units mobil (sebelum pajak 10%)',
                  style: const TextStyle(color: AppColors.textGrey)),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              text: 'Continue',
              onPressed: () {
                if (days < 1) {
                  showErrorSnackBar(
                      context, 'Tanggal check-out harus setelah check-in');
                  return;
                }
                final draft = BookingDraft(
                  car: widget.car,
                  pickupDate: _pickupDate,
                  returnDate: _returnDate,
                  passengers: _passengers,
                  units: _units,
                  serviceType: _serviceType,
                  paymentMethodCode: _channel.code,
                );
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => CustomerInfoScreen(draft: draft)));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickDates,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border)),
            child: Row(children: [
              const Icon(Icons.calendar_month_outlined,
                  color: AppColors.textGrey, size: 20),
              const SizedBox(width: 12),
              Text(value)
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _stepper(String label, int value, ValueChanged<int> onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border)),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          IconButton(
              onPressed: value > 1 ? () => onChanged(value - 1) : null,
              icon: const Icon(Icons.remove_circle_outline)),
          Text('$value',
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          IconButton(
              onPressed: () => onChanged(value + 1),
              icon: const Icon(Icons.add_circle_outline,
                  color: AppColors.primary)),
        ]),
      ),
    ]);
  }
}

class SavedPaymentMethodsScreen extends StatefulWidget {
  const SavedPaymentMethodsScreen({super.key});
  @override
  State<SavedPaymentMethodsScreen> createState() =>
      _SavedPaymentMethodsScreenState();
}

class _SavedPaymentMethodsScreenState extends State<SavedPaymentMethodsScreen> {
  late Future<List<Map<String, dynamic>>> _future =
      ProfileService.savedPaymentMethods();

  void _reload() =>
      setState(() => _future = ProfileService.savedPaymentMethods());

  Future<void> _add() async {
    PaymentChannel selected = paymentChannels.first;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Simpan Metode Pembayaran'),
        content: StatefulBuilder(
          builder: (context, setLocal) => DropdownButton<String>(
            value: selected.code,
            isExpanded: true,
            items: paymentChannels
                .map(
                    (c) => DropdownMenuItem(value: c.code, child: Text(c.name)))
                .toList(),
            onChanged: (v) => setLocal(() =>
                selected = paymentChannels.firstWhere((e) => e.code == v)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Simpan')),
        ],
      ),
    );
    if (ok == true) {
      try {
        await ProfileService.addSavedPaymentMethod(
            selected.code, selected.name);
        _reload();
      } catch (e) {
        if (mounted) showErrorSnackBar(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Metode Pembayaran Tersimpan'),
          leading: const BackButton()),
      floatingActionButton: FloatingActionButton(
          onPressed: _add,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add)),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }
          if (snapshot.hasError) {
            return ErrorView(
                message: 'Gagal memuat metode pembayaran.', onRetry: _reload);
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const ErrorView(
                message:
                    'Belum ada metode pembayaran tersimpan.\nTekan tombol + untuk menambahkan channel SakuRupiah favoritmu.');
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final item = items[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: const Icon(Icons.payments_outlined,
                      color: AppColors.primary),
                  title: Text(item['label'].toString()),
                  subtitle: Text(item['method_code'].toString()),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () async {
                      await ProfileService.deleteSavedPaymentMethod(
                          item['id'].toString());
                      _reload();
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
