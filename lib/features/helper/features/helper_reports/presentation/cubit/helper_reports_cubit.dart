import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/helper_report_entities.dart';
import '../../domain/repositories/helper_reports_repository.dart';

abstract class HelperReportsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class HelperReportsInitial extends HelperReportsState {}

class HelperReportsLoading extends HelperReportsState {}

class HelperReportsLoaded extends HelperReportsState {
  final List<HelperReportEntity> reports;
  HelperReportsLoaded(this.reports);

  @override
  List<Object?> get props => [reports];
}

class HelperReportsError extends HelperReportsState {
  final String message;
  HelperReportsError(this.message);

  @override
  List<Object?> get props => [message];
}

class HelperReportsCubit extends Cubit<HelperReportsState> {
  final GetCachedReportsUseCase getCachedReportsUseCase;
  final SyncReportsUseCase syncReportsUseCase;
  final Stream<HelperReportEntity> resolutionStream;
  
  StreamSubscription? _resolutionSubscription;

  HelperReportsCubit({
    required this.getCachedReportsUseCase,
    required this.syncReportsUseCase,
    required this.resolutionStream,
  }) : super(HelperReportsInitial());

  Future<void> loadReports() async {
    emit(HelperReportsLoading());
    
    // First sync from notifications
    await syncReportsUseCase();
    
    final result = await getCachedReportsUseCase();
    result.fold(
      (f) => emit(HelperReportsError(f.message)),
      (reports) {
        emit(HelperReportsLoaded(reports));
        _listenForResolutions();
      },
    );
  }

  void _listenForResolutions() {
    _resolutionSubscription?.cancel();
    _resolutionSubscription = resolutionStream.listen((event) {
      if (state is HelperReportsLoaded) {
        final currentReports = (state as HelperReportsLoaded).reports;
        final index = currentReports.indexWhere((r) => r.reportId == event.reportId);
        
        List<HelperReportEntity> updatedReports;
        if (index != -1) {
          updatedReports = List.from(currentReports)..[index] = event;
        } else {
          updatedReports = [event, ...currentReports];
        }
        
        emit(HelperReportsLoaded(updatedReports));
      }
    });
  }

  int get unresolvedCount {
    if (state is HelperReportsLoaded) {
      return (state as HelperReportsLoaded).reports.where((r) => !r.isResolved).length;
    }
    return 0;
  }

  @override
  Future<void> close() {
    _resolutionSubscription?.cancel();
    return super.close();
  }
}
