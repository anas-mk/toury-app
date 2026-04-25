import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/invoice_entity.dart';
import '../../domain/usecases/get_invoices_usecase.dart';
import '../../domain/usecases/get_invoice_detail_usecase.dart';
import '../../domain/usecases/get_invoice_by_booking_usecase.dart';
import '../../domain/usecases/get_invoice_html_usecase.dart';
import 'user_invoices_state.dart';

class UserInvoicesCubit extends Cubit<UserInvoicesState> {
  final GetInvoicesUseCase getInvoicesUseCase;
  final GetInvoiceDetailUseCase getInvoiceDetailUseCase;
  final GetInvoiceByBookingUseCase getInvoiceByBookingUseCase;
  final GetInvoiceHtmlUseCase getInvoiceHtmlUseCase;

  int _currentPage = 1;
  final int _pageSize = 20;

  UserInvoicesCubit({
    required this.getInvoicesUseCase,
    required this.getInvoiceDetailUseCase,
    required this.getInvoiceByBookingUseCase,
    required this.getInvoiceHtmlUseCase,
  }) : super(UserInvoicesInitial());

  Future<void> getInvoices({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
    }
    
    if (_currentPage == 1) {
      emit(UserInvoicesLoading());
    }

    final result = await getInvoicesUseCase(GetInvoicesParams(page: _currentPage, pageSize: _pageSize));

    result.fold(
      (failure) => emit(UserInvoicesError(failure.message)),
      (invoices) {
        if (invoices.isEmpty && _currentPage == 1) {
          emit(UserInvoicesEmpty());
        } else {
          _currentPage++;
          emit(UserInvoicesLoaded(
            invoices: invoices,
            hasMore: invoices.length == _pageSize,
          ));
        }
      },
    );
  }

  Future<void> getInvoiceDetail(String invoiceId) async {
    emit(UserInvoiceDetailLoading());
    final result = await getInvoiceDetailUseCase(invoiceId);

    result.fold(
      (failure) => emit(UserInvoicesError(failure.message)),
      (invoice) => emit(UserInvoiceDetailLoaded(invoice)),
    );
  }

  Future<void> getInvoiceByBooking(String bookingId) async {
    emit(UserInvoiceDetailLoading());
    final result = await getInvoiceByBookingUseCase(bookingId);

    result.fold(
      (failure) => emit(UserInvoicesError(failure.message)),
      (invoice) => emit(UserInvoiceDetailLoaded(invoice)),
    );
  }

  void setInitialInvoice(InvoiceEntity invoice) {
    emit(UserInvoiceDetailLoaded(invoice));
  }

  Future<void> getInvoiceHtml(String invoiceId) async {
    emit(InvoiceHtmlLoading());
    final result = await getInvoiceHtmlUseCase(invoiceId);

    result.fold(
      (failure) => emit(UserInvoicesError(failure.message)),
      (html) => emit(InvoiceHtmlLoaded(html)),
    );
  }
}
