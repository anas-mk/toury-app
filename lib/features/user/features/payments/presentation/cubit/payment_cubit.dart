import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/payment_entity.dart';
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
  bool _initiateInFlight = false;

  /// Initiate payment.
  ///
  /// The backend resolves Cash synchronously: the `initiate` response will
  /// already carry `status: Paid` and no `paymentUrl`, so we MUST NOT open the
  /// WebView and MUST NOT wait for a SignalR push — we emit success directly.
  /// Online methods (MockCard, etc.) come back as `PaymentPending` with a
  /// `paymentUrl`; the WebView page subscribes to BookingPaymentChanged and
  /// only completes when SignalR delivers `Paid` or `Failed`.
  Future<void> initiatePayment(String bookingId, String method) async {
    if (_initiateInFlight) return;
    _initiateInFlight = true;
    try {
      emit(PaymentLoading());
      final result = await initiatePaymentUseCase(
        InitiatePaymentParams(bookingId: bookingId, method: method),
      );
      result.fold(
        (failure) => emit(PaymentFailed(failure.message)),
        (payment) {
          if (payment.status == PaymentStatus.paid) {
            emit(PaymentSuccess(payment));
          } else if (payment.status == PaymentStatus.failed) {
            emit(PaymentFailed('Payment failed'));
          } else {
            emit(PaymentInitiated(payment));
          }
        },
      );
    } finally {
      _initiateInFlight = false;
    }
  }

  Future<void> checkPaymentStatus(String paymentId) async {
    final result = await getPaymentUseCase(paymentId);
    result.fold(
      (failure) => emit(PaymentFailed(failure.message)),
      (payment) {
        if (payment.status == PaymentStatus.paid) {
          emit(PaymentSuccess(payment));
        } else if (payment.status == PaymentStatus.failed) {
          emit(PaymentFailed('Payment failed'));
        }
      },
    );
  }

  Future<void> completeMockPayment(String paymentId, bool success) async {
    emit(PaymentLoading());
    final result = await mockPaymentCompleteUseCase(
      MockPaymentCompleteParams(
        paymentId: paymentId,
        action: success ? 'approve' : 'reject',
      ),
    );
    result.fold(
      (failure) => emit(PaymentFailed(failure.message)),
      (_) async {
        if (success) {
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
