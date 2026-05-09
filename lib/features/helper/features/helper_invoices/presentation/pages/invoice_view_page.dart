import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/services/haptic_service.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/app_dimens.dart';
import '../../../../../../core/widgets/app_error_state.dart';
import '../../../../../../core/widgets/app_scaffold.dart';
import '../../../../../../core/widgets/app_snackbar.dart';
import '../cubit/helper_invoices_cubit.dart';

/// Renders the helper invoice receipt HTML inside a real WebView.
///
/// The backend already returns a fully styled HTML page from
/// `ApiConfig.helperInvoiceView(id)`, so we feed it directly into the
/// WebView using `loadHtmlString`. The user-side `UserInvoiceViewPage`
/// uses the same approach for the tourist receipt.
class InvoiceViewPage extends StatefulWidget {
  final String invoiceId;
  const InvoiceViewPage({super.key, required this.invoiceId});

  @override
  State<InvoiceViewPage> createState() => _InvoiceViewPageState();
}

class _InvoiceViewPageState extends State<InvoiceViewPage> {
  late final HelperInvoicesCubit _cubit;
  late final WebViewController _webController;
  bool _webReady = false;

  @override
  void initState() {
    super.initState();
    _cubit = sl<HelperInvoicesCubit>()..loadHtml(widget.invoiceId);
    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _webReady = true);
          },
        ),
      );
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  void _copyInvoiceId() {
    HapticService.light();
    Clipboard.setData(ClipboardData(text: widget.invoiceId));
    if (!mounted) return;
    AppSnackbar.info(context, 'Invoice ID copied');
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);

    return BlocProvider.value(
      value: _cubit,
      child: AppScaffold(
        backgroundColor: palette.scaffold,
        appBar: AppBar(
          backgroundColor: palette.scaffold,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: palette.textPrimary,
              size: 18,
            ),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Receipt',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'Copy invoice ID',
              onPressed: _copyInvoiceId,
              icon: Icon(
                Icons.copy_rounded,
                color: palette.textSecondary,
                size: 18,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
        ),
        body: BlocConsumer<HelperInvoicesCubit, HelperInvoicesState>(
          listenWhen: (_, n) => n is InvoiceHtmlLoaded,
          listener: (_, state) {
            if (state is InvoiceHtmlLoaded) {
              _webController.loadHtmlString(state.html);
            }
          },
          builder: (context, state) {
            if (state is InvoicesError) {
              return AppErrorState(
                title: 'Receipt unavailable',
                message: state.message,
                onRetry: () => _cubit.loadHtml(widget.invoiceId),
              );
            }

            return Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.circular(AppRadius.xl + AppSpacing.xs),
                    child: Container(
                      decoration: BoxDecoration(
                        color: palette.surfaceElevated,
                        borderRadius: BorderRadius.circular(
                          AppRadius.xl + AppSpacing.xs,
                        ),
                        border: Border.all(color: palette.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: palette.isDark ? 0.32 : 0.06,
                            ),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: WebViewWidget(controller: _webController),
                    ),
                  ),
                ),
                if (state is InvoiceHtmlLoading || !_webReady)
                  Positioned.fill(
                    child: Container(
                      color: palette.scaffold.withValues(alpha: 0.6),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 36,
                              height: 36,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: palette.primary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Preparing your receipt…',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: palette.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
