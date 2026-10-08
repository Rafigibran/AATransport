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

String formatDateId(DateTime d) {
  const months = [
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
