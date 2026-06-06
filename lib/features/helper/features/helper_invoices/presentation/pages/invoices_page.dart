import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/services/haptic_service.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/app_dimens.dart';
import '../../../../../../core/utils/currency_format.dart';
import '../../../../../../core/widgets/animations/fade_in_slide.dart';
import '../../../../../../core/widgets/app_error_state.dart';
import '../../../../../../core/widgets/app_loading.dart';
import '../../../../../../core/widgets/app_scaffold.dart';
import '../../domain/entities/invoice_entities.dart';
import '../cubit/helper_invoices_cubit.dart';
import '../data/static_invoices.dart';
import '../widgets/invoice_list_item.dart';

class InvoicesPage extends StatefulWidget {
  const InvoicesPage({super.key});

  @override
  State<InvoicesPage> createState() => _InvoicesPageState();
}

class _InvoicesPageState extends State<InvoicesPage> {
  late final HelperInvoicesCubit _cubit;
  late final HelperInvoicesCubit _summaryCubit;
  final ScrollController _scrollController = ScrollController();
  String? _activeFilter;

  static const _filters = <String?>[null, 'paid', 'pending', 'cancelled'];
  static const _filterLabels = <String?, String>{
    null: 'All',
    'paid': 'Paid',
    'pending': 'Pending',
    'cancelled': 'Cancelled',
  };

  @override
  void initState() {
    super.initState();
    _cubit = sl<HelperInvoicesCubit>()..loadInvoices();
    _summaryCubit = sl<HelperInvoicesCubit>()..loadSummary();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _cubit.loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _cubit.close();
    _summaryCubit.close();
    super.dispose();
  }

  void _setFilter(String? f) {
    HapticService.light();
    setState(() => _activeFilter = f);
    _cubit.loadInvoices(statusFilter: f);
  }

  SliverList _staticInvoicesSliver(String? filter) {
    final invoices = StaticInvoices.forFilter(filter);

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (ctx, i) => FadeInSlide(
          delay: Duration(milliseconds: 60 + (i * 30).clamp(0, 240)),
          child: InvoiceListItem(
            invoice: invoices[i],
            onTap: () {},
          ),
        ),
        childCount: invoices.length,
      ),
    );
  }

  SliverList _invoiceListSliver(List<InvoiceEntity> invoices, {required bool hasMore}) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (ctx, i) {
          if (i == invoices.length) {
            return hasMore
                ? const Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Center(child: AppSpinner.large()),
                  )
                : const SizedBox(height: AppSpacing.huge);
          }
          return FadeInSlide(
            delay: Duration(milliseconds: 60 + (i * 30).clamp(0, 240)),
            child: InvoiceListItem(invoice: invoices[i]),
          );
        },
        childCount: invoices.length + 1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);

    Widget body = RefreshIndicator.adaptive(
      onRefresh: () async {
        await _cubit.refresh();
        await _summaryCubit.loadSummary();
      },
      color: palette.primary,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          _SliverHeader(),
          SliverToBoxAdapter(
            child: BlocBuilder<HelperInvoicesCubit, HelperInvoicesState>(
              bloc: _summaryCubit,
              builder: (context, state) {
                if (state is InvoiceSummaryLoading ||
                    state is InvoicesInitial) {
                  return const _SummaryShimmer();
                }
                if (state is InvoiceSummaryLoaded) {
                  return FadeInSlide(
                    delay: const Duration(milliseconds: 80),
                    child: _SummaryCard(summary: state.summary),
                  );
                }
                if (state is InvoicesError) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: AppErrorState(
                      message: state.message,
                      onRetry: () => _summaryCubit.loadSummary(),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          SliverToBoxAdapter(
            child: FadeInSlide(
              delay: const Duration(milliseconds: 140),
              child: _FilterRow(
                filters: _filters,
                labels: _filterLabels,
                activeFilter: _activeFilter,
                onSelect: _setFilter,
              ),
            ),
          ),
          BlocBuilder<HelperInvoicesCubit, HelperInvoicesState>(
            bloc: _cubit,
            builder: (context, state) {
              if (state is InvoicesLoading) {
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, __) => const _InvoiceShimmer(),
                    childCount: 5,
                  ),
                );
              }
              if (state is InvoicesEmpty ||
                  (state is InvoicesLoaded && state.invoices.isEmpty)) {
                return _staticInvoicesSliver(_activeFilter);
              }
              if (state is InvoicesError) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppErrorState(
                    message: state.message,
                    onRetry: () => _cubit.refresh(),
                  ),
                );
              }
              if (state is InvoicesLoaded) {
                return _invoiceListSliver(
                  state.invoices,
                  hasMore: state.hasMore,
                );
              }
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            },
          ),
        ],
      ),
    );

    final mqWidth = MediaQuery.sizeOf(context).width;
    if (mqWidth > 720) {
      body = Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: body,
        ),
      );
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _cubit),
        BlocProvider.value(value: _summaryCubit),
      ],
      child: AppScaffold(backgroundColor: palette.scaffold, body: body),
    );
  }
}

// ─── Sliver Header ────────────────────────────────────────────────────────────
class _SliverHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);

    return SliverAppBar(
      backgroundColor: palette.scaffold,
      pinned: true,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: palette.textPrimary,
          size: 18,
        ),
        onPressed: () => context.pop(),
      ),
      title: Text(
        'Invoices',
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: palette.textPrimary,
        ),
      ),
      centerTitle: true,
    );
  }
}

// ─── Summary Card ────────────────────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final InvoiceSummaryEntity summary;
  const _SummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: palette.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: palette.primary.withValues(alpha: 0.20)),
        boxShadow: [
          BoxShadow(
            color: palette.primary.withValues(alpha: 0.12),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Net Earnings',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: palette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    Money.egp(summary.netAmount),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: palette.success,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: palette.surfaceInset,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.receipt_long_rounded,
                      color: palette.textSecondary,
                      size: 14,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '${summary.invoiceCount}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: palette.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Divider(color: palette.divider, height: 1),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _SummaryStat(
                  label: 'Gross',
                  value: Money.egp(summary.grossAmount),
                  color: palette.textPrimary,
                  icon: Icons.trending_up_rounded,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: palette.divider,
              ),
              Expanded(
                child: _SummaryStat(
                  label: 'Commission',
                  value: '- ${Money.egp(summary.commissionAmount)}',
                  color: palette.danger,
                  icon: Icons.percent_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _SummaryStat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: palette.textMuted, size: 12),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: palette.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

// ─── Filter Row ──────────────────────────────────────────────────────────────
class _FilterRow extends StatelessWidget {
  final List<String?> filters;
  final Map<String?, String> labels;
  final String? activeFilter;
  final ValueChanged<String?> onSelect;

  const _FilterRow({
    required this.filters,
    required this.labels,
    required this.activeFilter,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((f) {
            final selected = activeFilter == f;
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: _FilterChip(
                label: labels[f]!,
                selected: selected,
                onTap: () => onSelect(f),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md + AppSpacing.xs,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            gradient: selected
                ? LinearGradient(
                    colors: [palette.primary, palette.primaryStrong],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: selected ? null : palette.surfaceElevated,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? Colors.transparent : palette.border,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: palette.primary.withValues(alpha: 0.22),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: selected ? Colors.white : palette.textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Shimmer / Skeleton ──────────────────────────────────────────────────────
class _SummaryShimmer extends StatelessWidget {
  const _SummaryShimmer();

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      height: 156,
      decoration: BoxDecoration(
        color: palette.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
      ),
    );
  }
}

class _InvoiceShimmer extends StatelessWidget {
  const _InvoiceShimmer();

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      height: 90,
      decoration: BoxDecoration(
        color: palette.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.xl + AppSpacing.xs),
      ),
    );
  }
}
