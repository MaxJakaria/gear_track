extension CurrencyFormatter on num {
  String toCurrency([String symbol = '৳']) {
    if (this < 0) {
      final absVal = abs();
      if (absVal % 1 == 0) {
        return '-$symbol${absVal.toInt()}';
      }
      return '-$symbol${absVal.toStringAsFixed(2)}';
    }
    if (this % 1 == 0) {
      return '$symbol${toInt()}';
    }
    return '$symbol${toStringAsFixed(2)}';
  }
}
