bool isValidEmail(String value) {
  return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim());
}

bool isValidIndonesianPhone(String value) {
  final digits = value.replaceAll(RegExp(r'[^0-9+]'), '');
  return RegExp(r'^(\+?62|0)8\d{7,13}$').hasMatch(digits);
}
