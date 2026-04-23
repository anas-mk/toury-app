import 'package:flutter_bloc/flutter_bloc.dart';

class RouteCubit extends Cubit<void> {
  RouteCubit() : super(null);

  void buildRoute({required double destinationLat, required double destinationLng}) {
    // Mock implementation
    print('RouteCubit: Building route to ($destinationLat, $destinationLng).');
  }

  void updateRoute({required double destinationLat, required double destinationLng}) {
    // Mock implementation
    print('RouteCubit: Updating route to ($destinationLat, $destinationLng).');
  }

  void clearRoute() {
    // Mock implementation
    print('RouteCubit: Cleared route.');
  }
}
