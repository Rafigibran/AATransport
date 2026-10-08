import 'package:flutter/material.dart';
import '../../models/car.dart';
import '../../services/app_services.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common_widgets.dart';
import 'customer_info_screen.dart';

class BookingInfoScreen extends StatefulWidget {
  final Car car;
  final DateTime? initialPickupDate;
  final DateTime? initialReturnDate;
  final int? initialPassengers;
  final int? initialUnits;
  const BookingInfoScreen({
    super.key,
    required this.car,
    this.initialPickupDate,
    this.initialReturnDate,
    this.initialPassengers,
    this.initialUnits,
  });
  @override
  State<BookingInfoScreen> createState() => _BookingInfoScreenState();
}

class _BookingInfoScreenState extends State<BookingInfoScreen> {
  late DateTime _pickupDate;
  late DateTime _returnDate;
  late int _passengers;
  late int _units;
  String _serviceType = 'Dengan Sopir';
  PaymentChannel _channel =
      paymentChannels.firstWhere((c) => c.code == 'QRISC');
  AppSettings _settings = const AppSettings();

  @override
  void initState() {
    super.initState();
    _pickupDate =
        widget.initialPickupDate ?? DateTime.now().add(const Duration(days: 7));
    _returnDate =
        widget.initialReturnDate ?? DateTime.now().add(const Duration(days: 10));
    _passengers = (widget.initialPassengers ?? 1).clamp(1, widget.car.seats);
    _units = (widget.initialUnits ?? 1).clamp(1, widget.car.totalUnits);
    SettingsService.fetchSettings().then((settings) {
      if (mounted) setState(() => _settings = settings);
    });
    ProfileService.savedPaymentMethods().then((methods) {
      if (!mounted || methods.isEmpty) return;
      final methodCode = methods.first['method_code']?.toString();
      final saved = paymentChannels
          .where((channel) => channel.code == methodCode)
          .toList();
      if (saved.isNotEmpty) setState(() => _channel = saved.first);
    });
  }

  int _estimateTotal(int rawDays) {
    final days = rawDays < 1 ? 1 : rawDays;
    final subtotal = widget.car.price * days * _units;
    final tax = (subtotal * _settings.taxPercent / 100).round();
    final fee = (subtotal * _settings.feePercent / 100).round();
    return subtotal + tax + fee;
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
                          subtitle: Text(
                              '${formatRupiah(c.minAmount)} - ${formatRupiah(c.maxAmount)}'),
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
                      (v) => setState(() => _passengers = v),
                      maxValue: widget.car.seats)),
              const SizedBox(width: 12),
              Expanded(
                  child: _stepper(
                      'Mobil', _units, (v) => setState(() => _units = v),
                      maxValue: widget.car.totalUnits)),
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
                  'Perkiraan total: ${formatRupiah(_estimateTotal(days))} untuk ${days < 1 ? 1 : days} hari x $_units mobil'
                  '${_settings.taxPercent > 0 || _settings.feePercent > 0 ? ' (termasuk pajak/fee sesuai pengaturan admin)' : ' (tanpa pajak dan fee)'}',
                  style: const TextStyle(color: AppColors.textGrey)),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              text: 'Continue',
              onPressed: () async {
                if (days < 1) {
                  showErrorSnackBar(
                      context, 'Tanggal kembali harus setelah tanggal ambil');
                  return;
                }
                if (_passengers > widget.car.seats) {
                  showErrorSnackBar(context,
                      'Jumlah penumpang melebihi kapasitas ${widget.car.seats} kursi');
                  return;
                }
                if (_units > widget.car.totalUnits) {
                  showErrorSnackBar(context,
                      'Jumlah unit melebihi armada yang tersedia (${widget.car.totalUnits} unit)');
                  return;
                }
                final available = await BookingService.availableUnits(
                  carId: widget.car.id,
                  pickupDate: _pickupDate,
                  returnDate: _returnDate,
                  totalUnits: widget.car.totalUnits,
                );
                if (!context.mounted) return;
                if (_units > available) {
                  showErrorSnackBar(context,
                      'Mobil tidak tersedia pada tanggal tersebut. Sisa unit tersedia: $available');
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
                  settings: _settings,
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

  Widget _stepper(String label, int value, ValueChanged<int> onChanged,
      {int? maxValue}) {
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
              onPressed: maxValue == null || value < maxValue
                  ? () => onChanged(value + 1)
                  : null,
              icon: Icon(Icons.add_circle_outline,
                  color: maxValue == null || value < maxValue
                      ? AppColors.primary
                      : AppColors.textGrey)),
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
                      try {
                        await ProfileService.deleteSavedPaymentMethod(
                            item['id'].toString());
                        _reload();
                      } catch (e) {
                        if (context.mounted) showErrorSnackBar(context, e);
                      }
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
