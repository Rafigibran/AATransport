import 'package:flutter/material.dart';
import '../../l10n/app_strings.dart';
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
  String _serviceType = '';
  AppSettings _settings = const AppSettings();

  @override
  void initState() {
    super.initState();
    _serviceType = tr('bi_service_driver');
    _pickupDate =
        widget.initialPickupDate ?? DateTime.now().add(const Duration(days: 7));
    _returnDate =
        widget.initialReturnDate ?? DateTime.now().add(const Duration(days: 10));
    _passengers = (widget.initialPassengers ?? 1).clamp(1, widget.car.seats);
    _units = (widget.initialUnits ?? 1).clamp(1, widget.car.totalUnits);
    SettingsService.fetchSettings().then((settings) {
      if (mounted) setState(() => _settings = settings);
    });
  }

  List<String> get _serviceTypes => [
        tr('bi_service_driver'),
        tr('bi_service_nodriver'),
        tr('bi_service_airport'),
        tr('bi_service_daily'),
      ];

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

  @override
  Widget build(BuildContext context) {
    final days = _returnDate.difference(_pickupDate).inDays;
    final billableDays = days < 1 ? 1 : days;
    return Scaffold(
      appBar:
          AppBar(title: Text(tr('bi_title')), leading: const BackButton()),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CarCard(car: widget.car, horizontal: true),
            _dateField(tr('bi_pickup'), formatDate(_pickupDate)),
            _dateField(tr('bi_return'), formatDate(_returnDate)),
            Row(children: [
              Expanded(
                  child: _stepper(tr('bi_passengers'), _passengers,
                      (v) => setState(() => _passengers = v),
                      maxValue: widget.car.seats)),
              const SizedBox(width: 12),
              Expanded(
                  child: _stepper(tr('bi_units'), _units,
                      (v) => setState(() => _units = v),
                      maxValue: widget.car.totalUnits)),
            ]),
            const SizedBox(height: 18),
            InputDecorator(
              decoration: InputDecoration(
                  labelText: tr('bi_service'),
                  prefixIcon: const Icon(Icons.meeting_room_outlined)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _serviceType,
                  isExpanded: true,
                  items: _serviceTypes
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
              leading: const Icon(Icons.chat_outlined,
                  color: AppColors.primary),
              title: Text(tr('bi_payment'),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(tr('bi_payment_wa')),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Text(
                  tr('bi_estimate', {
                        'total': formatMoney(_estimateTotal(days)),
                        'days': '$billableDays',
                        'units': '$_units',
                      }) +
                      ((_settings.taxPercent > 0 || _settings.feePercent > 0)
                          ? tr('bi_estimate_tax')
                          : tr('bi_estimate_notax')),
                  style: const TextStyle(color: AppColors.textGrey)),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              text: tr('common_continue'),
              onPressed: () async {
                if (days < 1) {
                  showErrorSnackBar(context, tr('bi_err_dates'));
                  return;
                }
                if (_passengers > widget.car.seats) {
                  showErrorSnackBar(context,
                      tr('bi_err_seats', {'n': '${widget.car.seats}'}));
                  return;
                }
                if (_units > widget.car.totalUnits) {
                  showErrorSnackBar(context,
                      tr('bi_err_units', {'n': '${widget.car.totalUnits}'}));
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
                  showErrorSnackBar(
                      context, tr('bi_err_avail', {'n': '$available'}));
                  return;
                }
                final draft = BookingDraft(
                  car: widget.car,
                  pickupDate: _pickupDate,
                  returnDate: _returnDate,
                  passengers: _passengers,
                  units: _units,
                  serviceType: _serviceType,
                  paymentMethodCode: 'WHATSAPP',
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
