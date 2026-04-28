class ActiveSosState {
  const ActiveSosState({
    required this.sosId,
    required this.bookingId,
    required this.startedAt,
    this.reason,
  });

  final String sosId;
  final String bookingId;
  final DateTime startedAt;
  final String? reason;

  Map<String, dynamic> toJson() => {
        'sosId': sosId,
        'bookingId': bookingId,
        'startedAt': startedAt.toUtc().toIso8601String(),
        if (reason != null && reason!.isNotEmpty) 'reason': reason,
      };

  factory ActiveSosState.fromJson(Map<String, dynamic> json) {
    final sosId = json['sosId']?.toString() ?? '';
    final bookingId = json['bookingId']?.toString() ?? '';
    final startedAtRaw = json['startedAt']?.toString();
    final parsedStartedAt = startedAtRaw == null || startedAtRaw.isEmpty
        ? null
        : DateTime.tryParse(startedAtRaw)?.toUtc();

    return ActiveSosState(
      sosId: sosId,
      bookingId: bookingId,
      startedAt: parsedStartedAt ?? DateTime.now().toUtc(),
      reason: json['reason']?.toString(),
    );
  }
}