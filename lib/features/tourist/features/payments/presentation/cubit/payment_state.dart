part of 'payment_cubit.dart';

abstract class PaymentState extends Equatable {
  const PaymentState();

  @override
  List<Object?> get props => [];
}

class PaymentInitial extends PaymentState {}

class PaymentLoading extends PaymentState {}

class PaymentCreated extends PaymentState {
  final PaymentEntity payment;

  const PaymentCreated(this.payment);

  @override
  List<Object?> get props => [payment];
}

class PaymentProcessing extends PaymentState {}

class PaymentSuccess extends PaymentState {
  final PaymentEntity? payment;

  const PaymentSuccess({this.payment});

  @override
  List<Object?> get props => [payment];
}

class PaymentFailed extends PaymentState {
  final String message;

  const PaymentFailed(this.message);

  @override
  List<Object?> get props => [message];
}

class PaymentWebviewOpen extends PaymentState {
  final String paymentUrl;
  final String paymentId;

  const PaymentWebviewOpen({required this.paymentUrl, required this.paymentId});

  @override
  List<Object?> get props => [paymentUrl, paymentId];
}
