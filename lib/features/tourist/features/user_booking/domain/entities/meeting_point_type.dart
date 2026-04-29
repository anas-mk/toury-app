/// Meeting-point preset.
///
/// The backend accepts the string names `"Custom"`, `"Hotel"`, `"Airport"`.
/// `Custom` is the default and means the traveler dropped a free-form pin.
enum MeetingPointType {
  custom('Custom', 'Custom location'),
  hotel('Hotel', 'Pickup from hotel'),
  airport('Airport', 'Airport meet & greet');

  /// Wire value sent to / received from the backend.
  final String wire;

  /// User-facing display string.
  final String label;

  const MeetingPointType(this.wire, this.label);

  static MeetingPointType fromWire(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'hotel':
        return MeetingPointType.hotel;
      case 'airport':
        return MeetingPointType.airport;
      case 'custom':
      default:
        return MeetingPointType.custom;
    }
  }
}
