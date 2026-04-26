import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/initiate_payment_usecase.dart';
import '../../domain/usecases/get_payment_usecase.dart';
import '../../domain/usecases/get_latest_payment_usecase.dart';
import '../../domain/usecases/mock_payment_complete_usecase.dart';
import 'payment_state.dart';

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

  Future<void> initiatePayment(String bookingId, String method) async {
    emit(PaymentLoading());
    final result = await initiatePaymentUseCase(InitiatePaymentParams(bookingId: bookingId, method: method));
    result.fold(
      (failure) => emit(PaymentFailed(failure.message)),
      (payment) => emit(PaymentInitiated(payment)),
    );
  }

  Future<void> checkPaymentStatus(String paymentId) async {
    final result = await getPaymentUseCase(paymentId);
    result.fold(
      (failure) => emit(PaymentFailed(failure.message)),
      (payment) {
        if (payment.status.name == 'paid') {
          emit(PaymentSuccess(payment));
        } else if (payment.status.name == 'failed') {
          emit(PaymentFailed('Payment failed'));
        }
      },
    );
  }

  Future<void> completeMockPayment(String paymentId, bool success) async {
    emit(PaymentLoading());
    final result = await mockPaymentCompleteUseCase(MockPaymentCompleteParams(paymentId: paymentId, action: success ? 'approve' : 'reject'));
    result.fold(
      (failure) => emit(PaymentFailed(failure.message)),
      (_) async {
        if (success) {
          // Fetch updated payment
          final paymentResult = await getPaymentUseCase(paymentId);
          paymentResult.fold(
            (failure) => emit(PaymentFailed(failure.message)),
            (payment) => emit(PaymentSuccess(payment)),
          );
        } else {
          emit(PaymentFailed('Payment rejected by mock gateway'));
        }
      },
    );
  }
}
