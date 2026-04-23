class HelperEntity {
  final String id;
  final String name;
  final double rating;
  final int reviewsCount;
  final String? profileImageUrl;
  final List<String> languages;
  final double pricePerHour;

  const HelperEntity({
    required this.id,
    required this.name,
    required this.rating,
    required this.reviewsCount,
    this.profileImageUrl,
    required this.languages,
    required this.pricePerHour,
  });
}
