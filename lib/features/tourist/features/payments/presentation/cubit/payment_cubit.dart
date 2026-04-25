import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/payment_entity.dart';
import '../../domain/usecases/initiate_payment_usecase.dart';
import '../../domain/usecases/get_payment_usecase.dart';
import '../../domain/usecases/get_latest_payment_usecase.dart';
import '../../domain/usecases/mock_payment_complete_usecase.dart';

part 'payment_state.dart';

class PaymentCubit extends Cubit<PaymentState> {
  final InitiatePaymentUseCase initiatePaymentUseCase;
  final GetPaymentUseCase getPaymentUseCase;
  final GetLatestPaymentUseCase getLatestPaymentUseCase;
  final MockPaymentCompleteUseCase mockPaymentCompleteUseCase;

  PaymentCubit({
    required this.initiatePaymentUseCase,
    required this.getPaymentUseCase,
    required this.getLatestPaymentUseCase,
    required this.mockPaymentCompleteUseCase,
  }) : super(PaymentInitial());

  void setInitial() {
    emit(PaymentInitial());
  }

  Future<void> initiatePayment(String bookingId, String method) async {
    emit(PaymentLoading());
    final result = await initiatePaymentUseCase(InitiatePaymentParams(bookingId: bookingId, method: method));

    result.fold(
      (failure) => emit(PaymentFailed(failure.message)),
      (payment) {
        if (payment.status == 'Paid') {
          emit(PaymentSuccess(payment: payment));
        } else if (payment.method == 'MockCard' && payment.paymentUrl != null) {
          emit(PaymentWebviewOpen(paymentUrl: payment.paymentUrl!, paymentId: payment.paymentId));
        } else {
          emit(PaymentCreated(payment));
        }
      },
    );
  }

  Future<void> getPayment(String paymentId) async {
    emit(PaymentLoading());
    final result = await getPaymentUseCase(paymentId);

    result.fold(
      (failure) => emit(PaymentFailed(failure.message)),
      (payment) {
        if (payment.status == 'Paid') {
          emit(PaymentSuccess(payment: payment));
        } else if (payment.status == 'Failed') {
          emit(const PaymentFailed('Payment failed or was cancelled.'));
        } else {
          emit(PaymentCreated(payment));
        }
      },
    );
  }

  Future<void> getLatestPayment(String bookingId) async {
    emit(PaymentLoading());
    final result = await getLatestPaymentUseCase(bookingId);

    result.fold(
      (failure) => emit(PaymentFailed(failure.message)),
      (payment) {
        if (payment.status == 'Paid') {
          emit(PaymentSuccess(payment: payment));
        } else if (payment.status == 'Failed') {
          emit(const PaymentFailed('Payment failed or was cancelled.'));
        } else if (payment.status == 'Pending') {
          emit(PaymentCreated(payment));
        } else {
          emit(PaymentInitial());
        }
      },
    );
  }

  Future<void> mockPaymentComplete(String paymentId, String action) async {
    emit(PaymentProcessing());
    final result = await mockPaymentCompleteUseCase(MockPaymentCompleteParams(paymentId: paymentId, action: action));

    result.fold(
      (failure) => emit(PaymentFailed(failure.message)),
      (_) {
        // After mocking complete, fetch the updated payment status
        getPayment(paymentId);
      },
    );
  }

  void handlePaymentSignal(String paymentStatus) {
    if (paymentStatus == 'Paid') {
      emit(const PaymentSuccess());
    } else if (paymentStatus == 'Failed') {
      emit(const PaymentFailed('Payment was marked as failed via realtime update.'));
    }
    // Could handle other statuses if needed
  }
}
