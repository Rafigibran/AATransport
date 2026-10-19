import '../l10n/app_strings.dart';

/// Display exchange rate: 1 USD = [kIdrPerUsd] IDR.
///
/// English-locale users see prices in USD converted with this fixed rate.
/// Update the constant when the rate drifts materially.
const double kIdrPerUsd = 17000;

String formatRupiah(num value) {
  final int v = value.round();
  final sign = v < 0 ? '-' : '';
  final digits = v.abs().toString();
  final buf = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write('.');
    buf.write(digits[i]);
  }
  return '${sign}Rp$buf';
}

String formatUsd(num value) {
  final usd = value / kIdrPerUsd;
  final int whole = usd.round();
  final sign = whole < 0 ? '-' : '';
  final digits = whole.abs().toString();
  final buf = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }
  return '$sign\$$buf';
}

/// Locale-aware money: USD when the system language is English,
/// Rupiah otherwise.
String formatMoney(num value) =>
    AppStrings.isEnglish ? formatUsd(value) : formatRupiah(value);

String formatDateId(DateTime d) => formatDate(d);

String formatDate(DateTime d) {
  final months = AppStrings.isEnglish
      ? const [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec'
        ]
      : const [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'Mei',
          'Jun',
          'Jul',
          'Agu',
          'Sep',
          'Okt',
          'Nov',
          'Des'
        ];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}
