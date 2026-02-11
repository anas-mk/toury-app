import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../entities/location.dart';

/// Domain Layer - Repository Interface
/// يحدد العقد (Contract) الذي يجب على الـ Data Layer تنفيذه
abstract class LocationRepository {
  /// الحصول على الموقع الحالي للمستخدم
  Future<Either<Failure, Location>> getCurrentLocation();

  /// البحث عن مواقع بناءً على نص البحث
  Future<Either<Failure, List<Location>>> searchLocations(String query);

  /// الاستماع للتغييرات في موقع المستخدم (Stream)
  Stream<Location> watchCurrentLocation();
}