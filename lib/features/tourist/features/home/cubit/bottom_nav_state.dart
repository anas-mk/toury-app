import 'package:equatable/equatable.dart';

class BottomNavState extends Equatable {
  final int currentIndex;

  const BottomNavState(this.currentIndex);

  @override
  List<Object> get props => [currentIndex];
}
