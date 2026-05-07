import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/app_dimens.dart';
import '../../../../../../core/widgets/app_empty_state.dart';
import '../../../../../../core/widgets/app_error_state.dart';
import '../../../../../../core/widgets/app_loading.dart';
import '../../../../../../core/widgets/app_scaffold.dart';
import '../../../../../../core/widgets/basic_app_bar.dart';
import '../../domain/entities/helper_earnings_entities.dart';
import '../cubit/helper_bookings_cubits.dart';

class EarningsPage extends StatefulWidget {
  const EarningsPage({super.key});

  @override
  State<EarningsPage> createState() => _EarningsPageState();
}

class _EarningsPageState extends State<EarningsPage> {
  late final EarningsCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<EarningsCubit>();
    _cubit.load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: AppScaffold(
        appBar: const BasicAppBar(title: 'Earnings'),
        body: BlocBuilder<EarningsCubit, EarningsState>(
          builder: (context, state) {
            if (state is EarningsLoading) {
              return const Center(child: AppLoading(fullScreen: false));
            }
            if (state is EarningsError) {
              return AppErrorState(
                message: state.message,
                onRetry: () => _cubit.load(),
              );
            }
            if (state is EarningsLoaded) {
              return RefreshIndicator.adaptive(
                onRefresh: () async => _cubit.load(),
                color: Theme.of(context).colorScheme.primary,
                child: _buildContent(context, state.earnings),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, HelperEarnings e) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageGutter,
        AppSpacing.sm,
        AppSpacing.pageGutter,
        AppSpacing.huge,
      ),
      children: [
        _HeroCard(earnings: e, palette: palette),
        const SizedBox(height: AppSpacing.md + AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: _PCard(
                label: 'This Week',
                amount: e.week,
                accent: palette.primary,
                palette: palette,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _PCard(
                label: 'This Month',
                amount: e.month,
                accent: palette.accent,
                palette: palette,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md + AppSpacing.xs),
        _StatsCard(trips: e.completedTrips, palette: palette),
        const SizedBox(height: AppSpacing.xl),
        if (e.chartData.isNotEmpty) ...[
          Text(
            'Weekly Overview',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
          _BarChart(data: e.chartData, palette: palette),
          const SizedBox(height: AppSpacing.xl),
        ],
        Text(
          'Recent Transactions',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
        if (e.recentEarnings.isEmpty)
          AppEmptyState(
            icon: Icons.receipt_long_rounded,
            title: 'No transactions yet',
            message: 'Completed trip payouts will appear here.',
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
          )
        else
          ...e.recentEarnings.map(
            (item) => _TransactionTile(item: item, palette: palette),
          ),
      ],
    );
  }
}

// ── Hero Earnings Card ────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final HelperEarnings earnings;
  final AppColors palette;

  const _HeroCard({required this.earnings, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.giga),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            palette.success,
            Color.lerp(palette.success, Colors.black, 0.35)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        boxShadow: [
          BoxShadow(
            color: palette.success.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, AppSpacing.sm),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's Earnings",
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
          Text(
            '\$${earnings.today.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              height: 1.05,
            ),
          ),
          const SizedBox(height: AppSpacing.md + AppSpacing.xs),
          Row(
            children: [
              Icon(
                Icons.trending_up_rounded,
                color: Colors.white.withValues(alpha: 0.85),
                size: AppSize.iconSm,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${earnings.completedTrips} trips completed',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color accent;
  final AppColors palette;

  const _PCard({
    required this.label,
    required this.amount,
    required this.accent,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: palette.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: palette.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '\$${amount.toStringAsFixed(0)}',
            style: theme.textTheme.titleLarge?.copyWith(
              color: accent,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final int trips;
  final AppColors palette;

  const _StatsCard({required this.trips, required this.palette});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: palette.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: palette.border.withValues(alpha: 0.65)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
            decoration: BoxDecoration(
              color: palette.primarySoft.withValues(
                alpha: palette.isDark ? 0.45 : 0.9,
              ),
              borderRadius: BorderRadius.circular(AppRadius.md + AppSpacing.xs),
            ),
            child: Icon(
              Icons.directions_car_rounded,
              color: palette.primary,
              size: AppSize.iconMd + AppSpacing.xxs,
            ),
          ),
          const SizedBox(width: AppSpacing.md + AppSpacing.xs),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$trips',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Total Completed Trips',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: palette.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  final List<ChartDataPoint> data;
  final AppColors palette;

  const _BarChart({required this.data, required this.palette});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxV = data.fold(0.0, (p, d) => d.value > p ? d.value : p);
    return Container(
      height: 160,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: palette.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: palette.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: data.map((d) {
          final frac = maxV > 0 ? d.value / maxV : 0.0;
          final barH = frac * 90;
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '\$${d.value.toStringAsFixed(0)}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: palette.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              AnimatedContainer(
                duration: AppDurations.slow,
                curve: Curves.easeOut,
                width: 22,
                height: barH.clamp(4.0, 90.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [palette.primary, palette.success],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(
                    AppSpacing.xs + AppSpacing.xxs,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                d.label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: palette.textMuted,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final EarningItem item;
  final AppColors palette;

  const _TransactionTile({required this.item, required this.palette});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm + AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: palette.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: palette.border.withValues(alpha: 0.55)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: palette.successSoft.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.payments_rounded,
              color: palette.success,
              size: AppSize.iconMd,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.travelerName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${item.date.day}/${item.date.month}/${item.date.year}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '+\$${item.amount.toStringAsFixed(2)}',
            style: theme.textTheme.titleSmall?.copyWith(
              color: palette.success,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
