import 'package:news/core/constants/strings.dart';

class LocationCityModel {
  final String id;
  final String locationName;
  final String latitude;
  final String longitude;

  LocationCityModel(
      {required this.latitude,
      required this.longitude,
      required this.id,
      required this.locationName});

  factory LocationCityModel.fromJson(Map<String, dynamic> json) {
    return LocationCityModel(
        id: json[ID].toString(),
        locationName: json[LOCATION_NAME] ?? '',
        latitude: json[LATITUDE].toString(),
        longitude: json[LONGITUDE].toString());
  }
}
