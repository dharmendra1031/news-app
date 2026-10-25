import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/features/homepage/models/weather_data.dart';
import 'package:news/core/configs/app_config.dart';
import 'package:news/core/error_handler/error_message_keys.dart';

abstract class WeatherState {}

class WeatherInitial extends WeatherState {}

class WeatherFetchInProgress extends WeatherState {}

class WeatherFetchSuccess extends WeatherState {
  final WeatherDetails weatherData;

  WeatherFetchSuccess({required this.weatherData});
}

class WeatherFetchFailure extends WeatherState {
  final String errorMessage;

  WeatherFetchFailure(this.errorMessage);
}

class WeatherCubit extends Cubit<WeatherState> {
  WeatherCubit() : super(WeatherInitial());

  void getWeatherDetails(
      {required String langId, String? lat, String? lon}) async {
    try {
      emit(WeatherFetchInProgress());

      final weatherResponse = await Dio().get(
          '$weatherApiUrl${lat.toString()},${lon.toString()}&days=1&alerts=no&lang=$langId');
      if (weatherResponse.statusCode == 200) {
        emit(WeatherFetchSuccess(
            weatherData:
                WeatherDetails.fromJson(Map.from(weatherResponse.data))));
      } else {
        emit(WeatherFetchFailure(weatherResponse.statusMessage ??
            ErrorMessageKeys.defaultErrorMessage));
      }
    } catch (e) {
      emit(WeatherFetchFailure(e.toString()));
    }
  }
}
