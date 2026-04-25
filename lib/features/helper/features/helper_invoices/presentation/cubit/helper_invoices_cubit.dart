import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/invoice_entities.dart';
import '../../domain/usecases/invoice_usecases.dart';

// ──────────────────────────────────────────────────────────────────────────────
// States
// ──────────────────────────────────────────────────────────────────────────────
abstract class HelperInvoicesState extends Equatable {
  const HelperInvoicesState();
  @override
  List<Object?> get props => [];
}

class InvoicesInitial extends HelperInvoicesState {}
class InvoicesLoading extends HelperInvoicesState {}
class InvoicesLoaded extends HelperInvoicesState {
  final List<InvoiceEntity> invoices;
  final bool hasMore;
  final int currentPage;
  const InvoicesLoaded({required this.invoices, this.hasMore = false, this.currentPage = 1});
  @override
  List<Object?> get props => [invoices, hasMore, currentPage];
}
class InvoicesEmpty extends HelperInvoicesState {}
class InvoicesError extends HelperInvoicesState {
  final String message;
  const InvoicesError(this.message);
  @override
  List<Object?> get props => [message];
}

class InvoiceDetailLoading extends HelperInvoicesState {}
class InvoiceDetailLoaded extends HelperInvoicesState {
  final InvoiceDetailEntity detail;
  const InvoiceDetailLoaded(this.detail);
  @override
  List<Object?> get props => [detail];
}

class InvoiceSummaryLoading extends HelperInvoicesState {}
class InvoiceSummaryLoaded extends HelperInvoicesState {
  final InvoiceSummaryEntity summary;
  const InvoiceSummaryLoaded(this.summary);
  @override
  List<Object?> get props => [summary];
}

class InvoiceHtmlLoading extends HelperInvoicesState {}
class InvoiceHtmlLoaded extends HelperInvoicesState {
  final String html;
  final String invoiceId;
  const InvoiceHtmlLoaded({required this.html, required this.invoiceId});
  @override
  List<Object?> get props => [html, invoiceId];
}

// ──────────────────────────────────────────────────────────────────────────────
// Cubit
// ──────────────────────────────────────────────────────────────────────────────
class HelperInvoicesCubit extends Cubit<HelperInvoicesState> {
  final GetInvoicesUseCase getInvoicesUseCase;
  final GetInvoiceDetailUseCase getDetailUseCase;
  final GetInvoiceByBookingUseCase getByBookingUseCase;
  final GetInvoiceSummaryUseCase getSummaryUseCase;
  final GetInvoiceHtmlUseCase getHtmlUseCase;

  // Pagination state
  List<InvoiceEntity> _allInvoices = [];
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  String? _activeStatusFilter;

  HelperInvoicesCubit({
    required this.getInvoicesUseCase,
    required this.getDetailUseCase,
    required this.getByBookingUseCase,
    required this.getSummaryUseCase,
    required this.getHtmlUseCase,
  }) : super(InvoicesInitial());

  // ── List / Pagination ──────────────────────────────────────────────────────

  Future<void> loadInvoices({String? statusFilter}) async {
    if (isClosed) return;
    _currentPage = 1;
    _allInvoices = [];
    _hasMore = true;
    _activeStatusFilter = statusFilter;
    emit(InvoicesLoading());

    try {
      final invoices = await getInvoicesUseCase.execute(
        page: 1,
        status: _activeStatusFilter,
      );
      _allInvoices = invoices;
      _currentPage = 1;
      _hasMore = invoices.length >= 20;

      if (!isClosed) {
        invoices.isEmpty
            ? emit(InvoicesEmpty())
            : emit(InvoicesLoaded(invoices: List.of(_allInvoices), hasMore: _hasMore, currentPage: _currentPage));
      }
    } catch (e) {
      if (!isClosed) emit(InvoicesError(e.toString()));
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore || isClosed) return;
    _isLoadingMore = true;
    try {
      final next = await getInvoicesUseCase.execute(
        page: _currentPage + 1,
        status: _activeStatusFilter,
      );
      _allInvoices.addAll(next);
      _currentPage++;
      _hasMore = next.length >= 20;
      if (!isClosed) {
        emit(InvoicesLoaded(invoices: List.of(_allInvoices), hasMore: _hasMore, currentPage: _currentPage));
      }
    } catch (_) {
      // Keep existing list, silently fail on pagination
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> refresh() => loadInvoices(statusFilter: _activeStatusFilter);

  // ── Detail ─────────────────────────────────────────────────────────────────

  Future<void> loadDetail(String invoiceId) async {
    if (isClosed) return;
    emit(InvoiceDetailLoading());
    try {
      final detail = await getDetailUseCase.execute(invoiceId);
      if (!isClosed) emit(InvoiceDetailLoaded(detail));
    } catch (e) {
      if (!isClosed) emit(InvoicesError(e.toString()));
    }
  }

  Future<void> loadByBooking(String bookingId) async {
    if (isClosed) return;
    emit(InvoiceDetailLoading());
    try {
      final detail = await getByBookingUseCase.execute(bookingId);
      if (!isClosed) emit(InvoiceDetailLoaded(detail));
    } catch (e) {
      if (!isClosed) emit(InvoicesError(e.toString()));
    }
  }

  // ── Summary ────────────────────────────────────────────────────────────────

  Future<void> loadSummary() async {
    if (isClosed) return;
    emit(InvoiceSummaryLoading());
    try {
      final summary = await getSummaryUseCase.execute();
      if (!isClosed) emit(InvoiceSummaryLoaded(summary));
    } catch (e) {
      if (!isClosed) emit(InvoicesError(e.toString()));
    }
  }

  // ── HTML View ──────────────────────────────────────────────────────────────

  Future<void> loadHtml(String invoiceId) async {
    if (isClosed) return;
    emit(InvoiceHtmlLoading());
    try {
      final html = await getHtmlUseCase.execute(invoiceId);
      if (!isClosed) emit(InvoiceHtmlLoaded(html: html, invoiceId: invoiceId));
    } catch (e) {
      if (!isClosed) emit(InvoicesError(e.toString()));
    }
  }
}
