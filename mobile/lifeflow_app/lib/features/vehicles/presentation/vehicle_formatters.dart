String formatOdometer(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();

  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(digits[index]);
  }

  return '${buffer.toString()} km';
}

String formatCurrency(double value) {
  final isNegative = value < 0;
  final parts = value.abs().toStringAsFixed(2).split('.');
  final integer = parts.first;
  final buffer = StringBuffer();

  for (var index = 0; index < integer.length; index++) {
    if (index > 0 && (integer.length - index) % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(integer[index]);
  }

  return '${isNegative ? '-' : ''}R\$ ${buffer.toString()},${parts.last}';
}

String formatDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}
