import 'package:equatable/equatable.dart';

class HelperEligibilityEntity extends Equatable {
  final bool isEligible;
  final List<String> blockingReasons;

  const HelperEligibilityEntity({
    required this.isEligible,
    required this.blockingReasons,
  });

  @override
  List<Object?> get props => [isEligible, blockingReasons];
}
