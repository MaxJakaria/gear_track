extension CurrencyFormatter on num {
  String toCurrency([String symbol = '৳']) {
    if (this % 1 == 0) {
      return '$symbol${toInt()}';
    }
    return '$symbol${toStringAsFixed(2)}';
  }
}
