import 'package:news/core/api/api.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/features/homepage/models/location_city_model.dart';
import 'package:news/core/configs/app_config.dart';
import 'package:news/core/constants/strings.dart';

abstract class LocationCityState {}

class LocationCityInitial extends LocationCityState {}

class LocationCityFetchInProgress extends LocationCityState {}

class LocationCityFetchSuccess extends LocationCityState {
  final List<LocationCityModel> locationCity;
  final int totalLocations;
  final bool hasMoreFetchError;
  final bool hasMore;

  LocationCityFetchSuccess(
      {required this.locationCity,
      required this.totalLocations,
      required this.hasMoreFetchError,
      required this.hasMore});
}

class LocationCityFetchFailure extends LocationCityState {
  final String errorMessage;

  LocationCityFetchFailure(this.errorMessage);
}

class LocationCityCubit extends Cubit<LocationCityState> {
  LocationCityCubit() : super(LocationCityInitial());

  void getLocationCity() async {
    try {
      final result = await Api.sendApiRequest(
          body: {LIMIT: limitOfAPIData, OFFSET: 0},
          url: Api.getLocationCityApi);
      emit(LocationCityFetchSuccess(
          totalLocations: result[DATA][TOTAL],
          locationCity: (result[DATA][DATA] as List)
              .map((e) => LocationCityModel.fromJson(e))
              .toList(),
          hasMore: (result[DATA][DATA] as List)
                  .map((e) => LocationCityModel.fromJson(e))
                  .toList()
                  .length <
              result[DATA][TOTAL],
          hasMoreFetchError: false));
    } catch (e) {
      emit(LocationCityFetchFailure(e.toString()));
    }
  }

  void getMoreLocationCity() async {
    if (state is LocationCityFetchSuccess) {
      try {
        await Api.sendApiRequest(body: {
          LIMIT: limitOfAPIData,
          OFFSET:
              (state as LocationCityFetchSuccess).locationCity.length.toString()
        }, url: Api.getLocationCityApi)
            .then((value) {
          List<LocationCityModel> updatedResults =
              (state as LocationCityFetchSuccess).locationCity;
          updatedResults.addAll((value[DATA][DATA] as List)
              .map((e) => LocationCityModel.fromJson(e))
              .toList());
          emit(LocationCityFetchSuccess(
              locationCity: updatedResults,
              totalLocations: value[DATA][TOTAL],
              hasMoreFetchError: false,
              hasMore: updatedResults.length < value[DATA][TOTAL]));
        });
      } catch (e) {
        emit(LocationCityFetchSuccess(
            locationCity: (state as LocationCityFetchSuccess).locationCity,
            totalLocations: (state as LocationCityFetchSuccess).totalLocations,
            hasMoreFetchError: true,
            hasMore: (state as LocationCityFetchSuccess).hasMore));
      }
    }
  }

  bool hasMoreLocation() {
    return (state is LocationCityFetchSuccess)
        ? (state as LocationCityFetchSuccess).hasMore
        : false;
  }

  List<LocationCityModel> getLocationCityList() {
    return (state is LocationCityFetchSuccess)
        ? (state as LocationCityFetchSuccess).locationCity
        : [];
  }

  int getLocationIndex({required String locationName}) {
    return (state is LocationCityFetchSuccess)
        ? (state as LocationCityFetchSuccess)
            .locationCity
            .indexWhere((element) => element.locationName == locationName)
        : 0;
  }
}
