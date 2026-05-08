import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/theme/brand_tokens.dart';
import '../../domain/usecases/get_invoice_html_usecase.dart';

class UserInvoiceViewPage extends StatefulWidget {
  final String invoiceId;
  const UserInvoiceViewPage({super.key, required this.invoiceId});

  @override
  State<UserInvoiceViewPage> createState() => _UserInvoiceViewPageState();
}

class _UserInvoiceViewPageState extends State<UserInvoiceViewPage> {
  late final WebViewController _controller;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFF5F7FA))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
        ),
      );
    _loadHtml();
  }

  Future<void> _loadHtml() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await sl<GetInvoiceHtmlUseCase>()(widget.invoiceId);
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _loading = false;
        _error = failure.message;
      }),
      (html) => _controller.loadHtmlString(html),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandTokens.bgSoft,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _TopBar(onBack: () => context.pop()),
            Expanded(
              child: _error != null
                  ? _ErrorView(message: _error!, onRetry: _loadHtml)
                  : Stack(
                      children: [
                        WebViewWidget(controller: _controller),
                        if (_loading)
                          LinearProgressIndicator(
                            color: BrandTokens.primaryBlue,
                            backgroundColor: BrandTokens.primaryBlue
                                .withValues(alpha: 0.12),
                            minHeight: 3,
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

// ─── Top bar ──────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final VoidCallback onBack;
  const _TopBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticFeedback.selectionClick();
              onBack();
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: BrandTokens.primaryBlue.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.arrow_back_rounded,
                color: BrandTokens.primaryBlue,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'RAFIQ',
            style: TextStyle(
              inherit: false,
              fontFamily: 'PermanentMarker',
              fontSize: 28,
              color: BrandTokens.primaryBlue,
            ),
          ),
          const Spacer(),
          Text(
            'Receipt',
            style: BrandTokens.body(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: BrandTokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Error ─────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long_outlined,
                size: 48, color: BrandTokens.textMuted),
            const SizedBox(height: 12),
            Text(
              'Could not load receipt',
              style: BrandTokens.heading(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: BrandTokens.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: BrandTokens.body(
                  fontSize: 13, color: BrandTokens.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                onRetry();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: BrandTokens.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
