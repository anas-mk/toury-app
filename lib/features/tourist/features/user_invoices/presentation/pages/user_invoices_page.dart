import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/theme/brand_tokens.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/localization/app_localizations.dart';
import '../../../../../../core/widgets/brand/mesh_gradient.dart';
import '../../../../../../core/widgets/animations/fade_in_slide.dart';
import '../../../../../../core/di/injection_container.dart';
import '../cubit/user_invoices_cubit.dart';
import '../../domain/entities/invoice_entity.dart';

class UserInvoicesPage extends StatefulWidget {
  const UserInvoicesPage({super.key});

  @override
  State<UserInvoicesPage> createState() => _UserInvoicesPageState();
}

class _UserInvoicesPageState extends State<UserInvoicesPage> {
  late final UserInvoicesCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<UserInvoicesCubit>()..loadInvoices();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        body: Stack(
          children: [
            // 1. Mesh Gradient Header
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 280,
              child: ClipPath(
                clipper: _HeaderClipper(),
                child: const MeshGradientBackground(),
              ),
            ),

            // 2. Main Content
            CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar(
                  expandedHeight: 0,
                  floating: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  title: Text(
                    loc.translate('wallet'),
                    style: BrandTokens.heading(color: Colors.white),
                  ),
                  centerTitle: true,
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        // Balance Card
                        FadeInSlide(
                          duration: const Duration(milliseconds: 600),
                          child: _WalletBalanceCard(),
                        ),
                        const SizedBox(height: 32),
                        // Transaction Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              loc.translate('recent_transactions'),
                              style: BrandTokens.heading(fontSize: 18),
                            ),
                            TextButton(
                              onPressed: () {},
                              child: Text(loc.translate('view_all')),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // 3. Transactions List
                BlocBuilder<UserInvoicesCubit, UserInvoicesState>(
                  builder: (context, state) {
                    if (state is UserInvoicesLoading) {
                      return const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (state is UserInvoicesLoaded) {
                      if (state.invoices.isEmpty) {
                        return SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.receipt_long_rounded, 
                                  size: 64, 
                                  color: theme.disabledColor.withValues(alpha: 0.3)
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  loc.translate('no_transactions'),
                                  style: BrandTokens.body(color: theme.disabledColor),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final invoice = state.invoices[index];
                              return FadeInSlide(
                                delay: Duration(milliseconds: 100 + (index * 50)),
                                child: _TransactionTile(invoice: invoice),
                              );
                            },
                            childCount: state.invoices.length,
                          ),
                        ),
                      );
                    }

                    if (state is UserInvoicesError) {
                      return SliverFillRemaining(
                        child: Center(child: Text(state.message)),
                      );
                    }

                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  },
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletBalanceCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: isDark 
          ? Colors.white.withValues(alpha: 0.08) 
          : Colors.white.withValues(alpha: 0.9),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Glass effect shine
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Balance',
                        style: BrandTokens.body(
                          color: isDark ? Colors.white70 : Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Icon(
                        Icons.account_balance_wallet_rounded,
                        color: isDark ? Colors.white54 : BrandTokens.primaryBlue.withValues(alpha: 0.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '1,250.00 EGP',
                    style: BrandTokens.heading(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : BrandTokens.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.add_rounded,
                          label: 'Top Up',
                          onTap: () {},
                          color: BrandTokens.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.send_rounded,
                          label: 'Transfer',
                          onTap: () {},
                          color: BrandTokens.accentAmber,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: color.withValues(alpha: 0.1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: BrandTokens.body(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final InvoiceEntity invoice;
  const _TransactionTile({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: InkWell(
        onTap: () => context.push('/invoice-detail/${invoice.invoiceId}', extra: invoice),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: BrandTokens.primaryBlue.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                color: BrandTokens.primaryBlue.withValues(alpha: 0.6),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trip to ${invoice.destinationCity}',
                    style: BrandTokens.body(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('MMM d, yyyy • hh:mm a').format(invoice.issuedAt),
                    style: BrandTokens.body(
                      fontSize: 12,
                      color: theme.disabledColor,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${invoice.currency} ${invoice.totalAmount.toStringAsFixed(2)}',
                  style: BrandTokens.numeric(
                    fontSize: 16,
                    color: isDark ? Colors.white : BrandTokens.primaryBlue,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'PAID',
                    style: BrandTokens.body(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.green,
                    ),
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

class _HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 60);
    path.quadraticBezierTo(
      size.width / 2, size.height,
      size.width, size.height - 60,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
