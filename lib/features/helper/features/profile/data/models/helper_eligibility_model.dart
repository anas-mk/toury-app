import '../../domain/entities/helper_eligibility_entity.dart';

class HelperEligibilityModel extends HelperEligibilityEntity {
  const HelperEligibilityModel({
    required super.isEligible,
    required super.blockingReasons,
  });

  factory HelperEligibilityModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    final blockingReasonsRaw = data['blockingReasons'] as List<dynamic>? ?? [];

    return HelperEligibilityModel(
      isEligible: data['isEligible'] as bool? ?? false,
      blockingReasons: blockingReasonsRaw.map((e) => e.toString()).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isEligible': isEligible,
      'blockingReasons': blockingReasons,
    };
  }
}
