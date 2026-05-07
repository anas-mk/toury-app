import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/app_dimens.dart';
import '../../../../../../core/widgets/app_empty_state.dart';
import '../../../../../../core/widgets/app_error_state.dart';
import '../../../../../../core/widgets/app_loading.dart';
import '../../../../../../core/widgets/app_scaffold.dart';
import '../../domain/entities/invoice_entities.dart';
import '../cubit/helper_invoices_cubit.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);

    Widget scrollBody = RefreshIndicator.adaptive(
      onRefresh: () async {
        await _cubit.refresh();
        await _summaryCubit.loadSummary();
      },
      color: theme.colorScheme.primary,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ── App Bar ──────────────────────────────────────────────────────
          SliverAppBar(
            backgroundColor: palette.scaffold,
            expandedHeight: 180,
            pinned: true,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: palette.textPrimary,
              ),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.filter_list_rounded,
                  color: palette.textPrimary,
                ),
                onPressed: () => _showFilterSheet(context),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(background: _buildHeader(context)),
          ),

          // ── Summary Card ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: BlocBuilder<HelperInvoicesCubit, HelperInvoicesState>(
              bloc: _summaryCubit,
              builder: (context, state) {
                if (state is InvoiceSummaryLoading ||
                    state is InvoicesInitial) {
                  return const _SummaryShimmer();
                }
                if (state is InvoiceSummaryLoaded) {
                  return _SummaryCard(summary: state.summary);
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

          // ── Filter Chips ─────────────────────────────────────────────────
          SliverToBoxAdapter(child: _buildFilterChips(context)),

          // ── Invoice List ─────────────────────────────────────────────────
          BlocBuilder<HelperInvoicesCubit, HelperInvoicesState>(
            bloc: _cubit,
            builder: (context, state) {
              if (state is InvoicesLoading) {
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, __) => const _InvoiceShimmerCard(),
                    childCount: 5,
                  ),
                );
              }

              if (state is InvoicesEmpty) {
                return SliverFillRemaining(child: _buildEmptyState(context));
              }

              if (state is InvoicesError) {
                return SliverFillRemaining(
                  child: AppErrorState(
                    message: state.message,
                    onRetry: () => _cubit.refresh(),
                  ),
                );
              }

              if (state is InvoicesLoaded) {
                return SliverList(
                  delegate: SliverChildBuilderDelegate((ctx, i) {
                    if (i == state.invoices.length) {
                      return state.hasMore
                          ? const Padding(
                              padding: EdgeInsets.all(AppSpacing.lg),
                              child: Center(child: AppSpinner.large()),
                            )
                          : const SizedBox(
                              height: AppSpacing.xxxl + AppSpacing.xs,
                            );
                    }
                    return _InvoiceCard(invoice: state.invoices[i]);
                  }, childCount: state.invoices.length + 1),
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
      scrollBody = Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: scrollBody,
        ),
      );
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _cubit),
        BlocProvider.value(value: _summaryCubit),
      ],
      child: AppScaffold(backgroundColor: palette.scaffold, body: scrollBody),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.pageGutter,
        MediaQuery.of(context).padding.top + AppSize.appBar,
        AppSpacing.pageGutter,
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette.isDark
              ? [palette.primaryStrong, palette.scaffold]
              : [
                  palette.primary,
                  palette.primaryStrong.withValues(alpha: 0.92),
                ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'Invoices',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Your complete financial history',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.88),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);
    final filters = [null, 'paid', 'pending', 'cancelled'];
    final labels = {
      null: 'All',
      'paid': 'Paid',
      'pending': 'Pending',
      'cancelled': 'Cancelled',
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((f) {
            final selected = _activeFilter == f;
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: FilterChip(
                label: Text(labels[f]!),
                selected: selected,
                onSelected: (_) {
                  setState(() => _activeFilter = f);
                  _cubit.loadInvoices(statusFilter: f);
                },
                backgroundColor: palette.surfaceElevated,
                selectedColor: palette.primarySoft,
                labelStyle: theme.textTheme.labelLarge?.copyWith(
                  color: selected ? palette.primary : palette.textSecondary,
                  fontSize: 12,
                ),
                side: BorderSide(
                  color: selected ? palette.primary : palette.border,
                ),
                checkmarkColor: palette.primary,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        final sheetPalette = AppColors.of(sheetCtx);
        final theme = Theme.of(sheetCtx);

        return Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xxl,
            AppSpacing.xl + AppSpacing.xs,
            AppSpacing.xxl,
            AppSpacing.xxl,
          ),
          decoration: BoxDecoration(
            color: sheetPalette.surfaceElevated,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.xl),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Filter Invoices',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: sheetPalette.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ...['All', 'Paid', 'Pending', 'Cancelled'].map((label) {
                final val = label == 'All' ? null : label.toLowerCase();

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    label,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: sheetPalette.textPrimary,
                    ),
                  ),
                  trailing: _activeFilter == val
                      ? Icon(Icons.check_rounded, color: sheetPalette.primary)
                      : null,
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    setState(() => _activeFilter = val);
                    _cubit.loadInvoices(statusFilter: val);
                  },
                );
              }),
              SizedBox(
                height: MediaQuery.paddingOf(sheetCtx).bottom + AppSpacing.sm,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: AppEmptyState(
        icon: Icons.receipt_long_rounded,
        title: 'No invoices yet',
        message: 'Completed trips will generate invoices here.',
        padding: const EdgeInsets.all(AppSpacing.xxxl + AppSpacing.sm),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Summary Card
// ──────────────────────────────────────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final InvoiceSummaryEntity summary;
  const _SummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');
    final theme = Theme.of(context);
    final palette = AppColors.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: palette.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: palette.primary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: palette.primary.withValues(alpha: 0.12),
            blurRadius: AppSpacing.xxl,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
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
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${summary.currency} ${fmt.format(summary.netAmount)}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: palette.success,
                      fontWeight: FontWeight.w700,
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
                  borderRadius: BorderRadius.circular(
                    AppRadius.sm + AppSpacing.xs,
                  ),
                ),
                child: Text(
                  '${summary.invoiceCount} invoices',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: palette.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.pageGutter),
          Divider(color: palette.divider),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              _SummaryItem(
                label: 'Gross',
                value: fmt.format(summary.grossAmount),
                currency: summary.currency,
                color: palette.textPrimary,
              ),
              const SizedBox(width: AppSize.hairline),
              Container(
                width: AppSize.border,
                height: 40,
                color: palette.divider,
              ),
              const SizedBox(width: AppSize.hairline),
              _SummaryItem(
                label: 'Commission',
                value: fmt.format(summary.commissionAmount),
                currency: summary.currency,
                color: palette.danger,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final String currency;
  final Color color;
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.currency,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);

    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: palette.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '$currency $value',
            style: theme.textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Invoice Card
// ──────────────────────────────────────────────────────────────────────────────
class _InvoiceCard extends StatelessWidget {
  final InvoiceEntity invoice;
  const _InvoiceCard({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);
    final fmt = NumberFormat('#,##0.00');
    final dateFmt = DateFormat('MMM d, yyyy');
    final isPaid = invoice.paymentStatus.toLowerCase() == 'paid';

    return GestureDetector(
      onTap: () => context.pushNamed(
        'helper-invoice-detail',
        pathParameters: {'id': invoice.invoiceId},
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        padding: const EdgeInsets.all(AppSpacing.pageGutter),
        decoration: BoxDecoration(
          color: palette.surfaceElevated,
          borderRadius: BorderRadius.circular(AppRadius.xl + AppSpacing.xs),
          border: Border.all(color: palette.border),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: (isPaid ? palette.success : palette.warning).withValues(
                  alpha: 0.12,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_rounded,
                color: isPaid ? palette.success : palette.warning,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.sm + AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '#${invoice.invoiceNumber}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    invoice.userName,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: palette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        color: palette.textMuted,
                        size: AppSize.iconSm,
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      Text(
                        invoice.destinationCity,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: palette.textMuted,
                        ),
                      ),
                      if (invoice.issuedAt != null) ...[
                        Text(' · ', style: TextStyle(color: palette.textMuted)),
                        Text(
                          dateFmt.format(invoice.issuedAt!),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: palette.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${invoice.currency} ${fmt.format(invoice.totalAmount)}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: palette.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                _StatusBadge(status: invoice.paymentStatus),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);
    final s = status.toLowerCase();

    late final Color color;
    switch (s) {
      case 'paid':
        color = palette.success;
        break;
      case 'pending':
        color = palette.warning;
        break;
      default:
        color = palette.danger;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        status.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 9,
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Shimmer Cards
// ──────────────────────────────────────────────────────────────────────────────
class _SummaryShimmer extends StatelessWidget {
  const _SummaryShimmer();

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      height: 148,
      decoration: BoxDecoration(
        color: palette.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
      ),
    );
  }
}

class _InvoiceShimmerCard extends StatelessWidget {
  const _InvoiceShimmerCard();

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
      height: 80,
      decoration: BoxDecoration(
        color: palette.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.xl + AppSpacing.xs),
      ),
    );
  }
}
