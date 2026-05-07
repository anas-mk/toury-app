import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/app_dimens.dart';
import '../../../../../../core/widgets/app_error_state.dart';
import '../../../../../../core/widgets/app_loading.dart';
import '../../../../../../core/widgets/app_scaffold.dart';
import '../../../../../../core/widgets/app_snackbar.dart';
import '../../../../../../core/widgets/basic_app_bar.dart';
import '../../../../../../core/di/injection_container.dart';
import '../cubit/helper_invoices_cubit.dart';

/// Renders the invoice HTML using Flutter's built-in text/html approach.
/// Since no webview package is present, we display it inside a scrollable
/// container and offer an external link via url_launcher if available.
class InvoiceViewPage extends StatefulWidget {
  final String invoiceId;
  const InvoiceViewPage({super.key, required this.invoiceId});

  @override
  State<InvoiceViewPage> createState() => _InvoiceViewPageState();
}

class _InvoiceViewPageState extends State<InvoiceViewPage> {
  late final HelperInvoicesCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<HelperInvoicesCubit>()..loadHtml(widget.invoiceId);
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
        appBar: const BasicAppBar(title: 'Receipt', centerTitle: false),
        body: BlocBuilder<HelperInvoicesCubit, HelperInvoicesState>(
          builder: (context, state) {
            if (state is InvoiceHtmlLoading) {
              return const Center(child: AppLoading(fullScreen: false));
            }

            if (state is InvoicesError) {
              return AppErrorState(
                title: 'Receipt unavailable',
                message: state.message,
                onRetry: () => _cubit.loadHtml(widget.invoiceId),
              );
            }

            if (state is InvoiceHtmlLoaded) {
              return _HtmlReceiptCard(
                html: state.html,
                invoiceId: state.invoiceId,
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

/// Parses and renders the receipt HTML as a structured visual card.
/// For full browser rendering, add flutter_inappwebview to pubspec.yaml.
class _HtmlReceiptCard extends StatelessWidget {
  final String html;
  final String invoiceId;
  const _HtmlReceiptCard({required this.html, required this.invoiceId});

  // Strip HTML tags for plain text display
  String _stripTags(String input) {
    return input
        .replaceAll(RegExp(r'<style[^>]*>.*?</style>', dotAll: true), '')
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);
    final plainText = _stripTags(html);

    return Column(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  decoration: BoxDecoration(
                    color: palette.surfaceElevated,
                    borderRadius: BorderRadius.circular(
                      AppRadius.md + AppSpacing.xs,
                    ),
                    border: Border.all(color: palette.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: palette.isDark ? 0.35 : 0.06,
                        ),
                        blurRadius: AppSpacing.xxl,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: SelectableText(
                    plainText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.textPrimary,
                      fontFamily: 'monospace',
                      height: 1.6,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.pageGutter,
            AppSpacing.md,
            AppSpacing.pageGutter,
            AppSpacing.xxl + MediaQuery.paddingOf(context).bottom,
          ),
          decoration: BoxDecoration(
            color: palette.scaffold,
            border: Border(top: BorderSide(color: palette.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    AppSnackbar.info(
                      context,
                      'Add url_launcher to open this receipt in the browser.',
                    );
                  },
                  icon: Icon(
                    Icons.open_in_browser_rounded,
                    size: AppSize.iconSm,
                    color: palette.textPrimary,
                  ),
                  label: Text(
                    'Open in Browser',
                    style: TextStyle(color: palette.textPrimary),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: palette.textPrimary,
                    side: BorderSide(color: palette.border),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md + AppSpacing.sm,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppRadius.sm + AppSpacing.xs,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
