import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0E1A),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          title: const Text('Receipt', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        body: BlocBuilder<HelperInvoicesCubit, HelperInvoicesState>(
          builder: (context, state) {
            if (state is InvoiceHtmlLoading) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)));
            }

            if (state is InvoicesError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Color(0xFFFF6B6B), size: 48),
                    const SizedBox(height: 12),
                    Text(state.message, style: const TextStyle(color: Colors.white54)),
                  ],
                ),
              );
            }

            if (state is InvoiceHtmlLoaded) {
              // Render HTML as plain receipt card since webview is not installed
              return _HtmlReceiptCard(html: state.html, invoiceId: state.invoiceId);
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
    final plainText = _stripTags(html);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: SelectableText(
                plainText,
                style: const TextStyle(
                  color: Color(0xFF1A1A2E),
                  fontSize: 12,
                  fontFamily: 'monospace',
                  height: 1.6,
                ),
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          decoration: const BoxDecoration(
            color: Color(0xFF0A0E1A),
            border: Border(top: BorderSide(color: Colors.white12)),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // With url_launcher: launchUrl(Uri.parse('${ApiConfig.baseUrl}/helper/invoices/$invoiceId/view'))
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Add url_launcher to open in browser'),
                        backgroundColor: Color(0xFF1A1F3C),
                      ),
                    );
                  },
                  icon: const Icon(Icons.open_in_browser_rounded, size: 16),
                  label: const Text('Open in Browser'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: BorderSide(color: Colors.white.withOpacity(0.1)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
