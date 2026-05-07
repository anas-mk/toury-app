import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/invoice_entity.dart';
import '../../domain/usecases/get_invoices_usecase.dart';
import '../../domain/usecases/get_invoice_detail_usecase.dart';
import '../../domain/usecases/get_invoice_by_booking_usecase.dart';
import '../../domain/usecases/get_invoice_html_usecase.dart';

abstract class UserInvoicesState extends Equatable {
  const UserInvoicesState();
  @override
  List<Object?> get props => [];
}

class UserInvoicesInitial extends UserInvoicesState {}
class UserInvoicesLoading extends UserInvoicesState {}
class UserInvoicesLoaded extends UserInvoicesState {
  final List<InvoiceEntity> invoices;
  final bool hasReachedMax;

  const UserInvoicesLoaded({
    required this.invoices,
    required this.hasReachedMax,
  });

  @override
  List<Object?> get props => [invoices, hasReachedMax];
}

class UserInvoicesError extends UserInvoicesState {
  final String message;
  const UserInvoicesError(this.message);

  @override
  List<Object?> get props => [message];
}

class UserInvoicesCubit extends Cubit<UserInvoicesState> {
  final GetInvoicesUseCase getInvoicesUseCase;
  final GetInvoiceDetailUseCase getInvoiceDetailUseCase;
  final GetInvoiceByBookingUseCase getInvoiceByBookingUseCase;
  final GetInvoiceHtmlUseCase getInvoiceHtmlUseCase;

  UserInvoicesCubit({
    required this.getInvoicesUseCase,
    required this.getInvoiceDetailUseCase,
    required this.getInvoiceByBookingUseCase,
    required this.getInvoiceHtmlUseCase,
  }) : super(UserInvoicesInitial());

  Future<void> loadInvoices() async {
    emit(UserInvoicesLoading());
    final result = await getInvoicesUseCase(GetInvoicesParams(page: 1, pageSize: 20));
    result.fold(
      (failure) => emit(UserInvoicesError(failure.message)),
      (invoices) => emit(UserInvoicesLoaded(
        invoices: invoices,
        hasReachedMax: invoices.length < 20,
      )),
    );
  }

  Future<void> loadMore() async {
    if (state is! UserInvoicesLoaded) return;
    final currentState = state as UserInvoicesLoaded;
    if (currentState.hasReachedMax) return;

    final nextPage = (currentState.invoices.length ~/ 20) + 1;
    final result = await getInvoicesUseCase(GetInvoicesParams(page: nextPage, pageSize: 20));

    result.fold(
      (failure) => null, // Silently fail load more
      (newInvoices) {
        if (newInvoices.isEmpty) {
          emit(UserInvoicesLoaded(
            invoices: currentState.invoices,
            hasReachedMax: true,
          ));
        } else {
          emit(UserInvoicesLoaded(
            invoices: currentState.invoices + newInvoices,
            hasReachedMax: newInvoices.length < 20,
          ));
        }
      },
    );
  }
}
