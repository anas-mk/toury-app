import 'package:equatable/equatable.dart';
import '../../domain/entities/invoice_entity.dart';

abstract class UserInvoicesState extends Equatable {
  const UserInvoicesState();

  @override
  List<Object?> get props => [];
}

class UserInvoicesInitial extends UserInvoicesState {}

class UserInvoicesLoading extends UserInvoicesState {}

class UserInvoicesLoaded extends UserInvoicesState {
  final List<InvoiceEntity> invoices;
  final bool hasMore;

  const UserInvoicesLoaded({required this.invoices, this.hasMore = false});

  @override
  List<Object?> get props => [invoices, hasMore];
}

class UserInvoicesEmpty extends UserInvoicesState {}

class UserInvoicesError extends UserInvoicesState {
  final String message;

  const UserInvoicesError(this.message);

  @override
  List<Object?> get props => [message];
}

class UserInvoiceDetailLoading extends UserInvoicesState {}

class UserInvoiceDetailLoaded extends UserInvoicesState {
  final InvoiceEntity invoice;

  const UserInvoiceDetailLoaded(this.invoice);

  @override
  List<Object?> get props => [invoice];
}

class InvoiceHtmlLoading extends UserInvoicesState {}

class InvoiceHtmlLoaded extends UserInvoicesState {
  final String html;

  const InvoiceHtmlLoaded(this.html);

  @override
  List<Object?> get props => [html];
}
