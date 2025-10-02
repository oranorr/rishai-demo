extension StringExtension on String {
  String capitalize() {
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }

  /// Капитализирует каждое слово в строке
  /// Например: "loose weight" -> "Loose Weight"
  String capitalizeWords() {
    if (isEmpty) return this;

    return split(' ')
        .map((word) => word.isEmpty ? word : word.capitalize())
        .join(' ');
  }
}
