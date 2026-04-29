import 'package:flutter/material.dart';
import '../../../../../../../core/theme/brand_typography.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: BrandTypography.title(),
    );
  }
}
