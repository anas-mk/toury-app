import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
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
}
