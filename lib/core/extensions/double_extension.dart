extension Ex on double {
  double toPrecision({int? n}) => double.parse(toStringAsFixed(n ?? 1));
}

extension IntEx on int {
  String comaThisNumber() {
    if (this >= 1000) {
      return (this / 1000).toStringAsFixed(3).replaceAll('.', ',');
    } else {
      return toString();
    }
  }
}
