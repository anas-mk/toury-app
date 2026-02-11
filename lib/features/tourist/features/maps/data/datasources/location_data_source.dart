import '../models/location_model.dart';


/// Data Source Interface - Location
/// يحدد العقد للتعامل مع مصادر البيانات
abstract class LocationDataSource {
  /// الحصول على الموقع الحالي
  Future<LocationModel> getCurrentLocation();

  /// البحث عن مواقع باستخدام Nominatim API
  Future<List<LocationModel>> searchLocations(String query);

  /// الاستماع للموقع الحالي
  Stream<LocationModel> watchCurrentLocation();
}