import 'package:flutter/material.dart';
import '../../../../../../../core/widgets/app_section_header.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return AppSectionHeader(title: title, padding: EdgeInsets.zero);
  }
}
