class TimeSlot {
  final int? id; // Slot ID from API
  final String label;
  final bool available;
  TimeSlot(this.label, {this.id, this.available = true});
}
