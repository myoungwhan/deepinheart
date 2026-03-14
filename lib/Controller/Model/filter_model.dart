class FilterOption {
  final String key;
  bool selected;
  FilterOption({required this.key, this.selected = true});
}

class FilterConfig {
  List<FilterOption> types; // Consultation types / Coin types
  String period; // Period
  DateTime? startDate;
  DateTime? endDate;
  String sortOrder; // Latest, Oldest, Duration...

  FilterConfig({
    required this.types,
    this.period = 'All Time',
    this.startDate,
    this.endDate,
    this.sortOrder = 'Latest',
  });
}
