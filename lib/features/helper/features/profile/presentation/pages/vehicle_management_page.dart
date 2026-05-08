import 'package:flutter/material.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/widgets/animations/fade_in_slide.dart';
import '../../domain/entities/car_entity.dart';

class VehicleManagementPage extends StatelessWidget {
  final CarEntity? car;
  const VehicleManagementPage({super.key, this.car});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: palette.scaffold,
      appBar: AppBar(
        leading: const _BackButton(),
        title: Text(
          'My Vehicle',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: palette.scaffold,
        actions: [
          if (car != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _CircleIconButton(
                icon: Icons.edit_outlined,
                onTap: () {},
              ),
            ),
        ],
      ),
      body: car == null ? _emptyState(context) : _filledState(context, car!),
    );
  }

  Widget _emptyState(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    palette.primary.withValues(alpha: 0.18),
                    const Color(0xFF7B61FF).withValues(alpha: 0.18),
                  ],
                ),
              ),
              child: Icon(
                Icons.directions_car_filled_outlined,
                size: 56,
                color: palette.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No vehicle registered',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your vehicle details to start offering transportation services to your customers.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: palette.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Add Vehicle'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filledState(BuildContext context, CarEntity c) {
    return ListView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        FadeInSlide(
          duration: const Duration(milliseconds: 500),
          child: _VehicleHeroCard(car: c),
        ),
        const SizedBox(height: 20),
        FadeInSlide(
          delay: const Duration(milliseconds: 100),
          child: _SectionTitle(
            title: 'Quick Specs',
            subtitle: 'At a glance',
          ),
        ),
        const SizedBox(height: 12),
        FadeInSlide(
          delay: const Duration(milliseconds: 150),
          child: _SpecsGrid(car: c),
        ),
        const SizedBox(height: 20),
        FadeInSlide(
          delay: const Duration(milliseconds: 200),
          child: _SectionTitle(
            title: 'Vehicle Details',
            subtitle: 'Full specifications',
          ),
        ),
        const SizedBox(height: 12),
        FadeInSlide(
          delay: const Duration(milliseconds: 250),
          child: _DetailsList(car: c),
        ),
        const SizedBox(height: 20),
        FadeInSlide(
          delay: const Duration(milliseconds: 300),
          child: _SectionTitle(
            title: 'Documents',
            subtitle: 'License & registration',
          ),
        ),
        const SizedBox(height: 12),
        FadeInSlide(
          delay: const Duration(milliseconds: 350),
          child: _DocumentsRow(car: c),
        ),
        const SizedBox(height: 24),
        FadeInSlide(
          delay: const Duration(milliseconds: 400),
          child: _DangerZone(),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  HERO VEHICLE CARD
// ──────────────────────────────────────────────────────────────────────────────

class _VehicleHeroCard extends StatelessWidget {
  final CarEntity car;
  const _VehicleHeroCard({required this.car});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette.isDark
              ? [
                  const Color(0xFF1F2937),
                  const Color(0xFF111827),
                ]
              : [
                  const Color(0xFF1E293B),
                  const Color(0xFF0F172A),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -50,
            right: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF7B61FF).withValues(alpha: 0.16),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -20,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.primary.withValues(alpha: 0.14),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF22C55E),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'ACTIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    car.carType.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Center(
                child: Container(
                  width: 180,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.directions_car_filled_rounded,
                    color: Colors.white,
                    size: 88,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                car.brand.toUpperCase(),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                car.model,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.14),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.confirmation_number_outlined,
                      color: Colors.white.withValues(alpha: 0.75),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'License Plate',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      car.licensePlate,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  SPECS GRID
// ──────────────────────────────────────────────────────────────────────────────

class _SpecsGrid extends StatelessWidget {
  final CarEntity car;
  const _SpecsGrid({required this.car});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SpecCard(
            icon: Icons.bolt_rounded,
            label: 'Energy',
            value: car.energyType,
            color: const Color(0xFFFFB020),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SpecCard(
            icon: Icons.palette_outlined,
            label: 'Color',
            value: car.color,
            color: const Color(0xFFFF6B9D),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SpecCard(
            icon: Icons.category_outlined,
            label: 'Type',
            value: car.carType,
            color: const Color(0xFF7B61FF),
          ),
        ),
      ],
    );
  }
}

class _SpecCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SpecCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: palette.isDark ? 0.18 : 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: palette.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  DETAILS LIST
// ──────────────────────────────────────────────────────────────────────────────

class _DetailsList extends StatelessWidget {
  final CarEntity car;
  const _DetailsList({required this.car});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final rows = [
      _Row('Brand', car.brand),
      _Row('Model', car.model),
      _Row('Color', car.color),
      _Row('License Plate', car.licensePlate),
      _Row('Energy Type', car.energyType),
      _Row('Vehicle Type', car.carType),
    ];

    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.border, width: 0.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i < rows.length - 1)
              Divider(height: 1, thickness: 0.5, color: palette.border),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: palette.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: palette.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  DOCUMENTS ROW
// ──────────────────────────────────────────────────────────────────────────────

class _DocumentsRow extends StatelessWidget {
  final CarEntity car;
  const _DocumentsRow({required this.car});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _DocCard(
            label: 'License Front',
            isUploaded: car.carLicenseFrontUrl != null && car.carLicenseFrontUrl!.isNotEmpty,
            imageUrl: car.carLicenseFrontUrl,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _DocCard(
            label: 'License Back',
            isUploaded: car.carLicenseBackUrl != null && car.carLicenseBackUrl!.isNotEmpty,
            imageUrl: car.carLicenseBackUrl,
          ),
        ),
      ],
    );
  }
}

class _DocCard extends StatelessWidget {
  final String label;
  final bool isUploaded;
  final String? imageUrl;

  const _DocCard({
    required this.label,
    required this.isUploaded,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);
    final color = isUploaded ? palette.success : palette.warning;

    return Container(
      height: 130,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUploaded ? color.withValues(alpha: 0.4) : palette.border,
          width: 1,
        ),
        image: (isUploaded && imageUrl != null && imageUrl!.isNotEmpty)
            ? DecorationImage(
                image: NetworkImage(imageUrl!),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withValues(alpha: 0.35),
                  BlendMode.darken,
                ),
              )
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: palette.isDark ? 0.20 : 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isUploaded ? Icons.check_circle_rounded : Icons.upload_file_rounded,
                color: color,
                size: 18,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: imageUrl != null && imageUrl!.isNotEmpty
                        ? Colors.white
                        : palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isUploaded ? 'Uploaded' : 'Tap to upload',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: imageUrl != null && imageUrl!.isNotEmpty
                        ? Colors.white.withValues(alpha: 0.85)
                        : palette.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  DANGER ZONE & SHARED
// ──────────────────────────────────────────────────────────────────────────────

class _DangerZone extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: palette.danger.withValues(alpha: palette.isDark ? 0.10 : 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: palette.danger.withValues(alpha: 0.20),
              width: 0.8,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: palette.danger.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: palette.danger,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Remove Vehicle',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: palette.danger,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'You won\'t be able to take ride jobs',
                      style: TextStyle(
                        fontSize: 12,
                        color: palette.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: palette.danger.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12.5,
              color: palette.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: palette.surface,
            shape: BoxShape.circle,
            border: Border.all(color: palette.border),
          ),
          child: Icon(icon, color: palette.textSecondary, size: 18),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.maybePop(context),
          customBorder: const CircleBorder(),
          child: Container(
            decoration: BoxDecoration(
              color: palette.surface,
              shape: BoxShape.circle,
              border: Border.all(color: palette.border),
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: palette.textPrimary,
              size: 16,
            ),
          ),
        ),
      ),
    );
  }
}
