import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ConnectivityCubit extends Cubit<ConnectivityState> {
  final ConnectivityService _connectivityService;
  late StreamSubscription _subscription;

  ConnectivityCubit(this._connectivityService) : super(ConnectivityInitial()) {
    _startMonitoring();
  }

  void _startMonitoring() {
    _subscription = _connectivityService.connectivityStream.listen((result) {
      if (result == ConnectivityResult.none) {
        emit(ConnectivityDisconnected());
      } else {
        emit(ConnectivityConnected(result));
      }
    });
  }

  Future<void> checkInitialConnection() async {
    final result = await _connectivityService.checkConnectivity();
    if (result == ConnectivityResult.none) {
      emit(ConnectivityDisconnected());
    } else {
      emit(ConnectivityConnected(result as ConnectivityResult));
    }
  }

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}

abstract class ConnectivityState extends Equatable {
  const ConnectivityState();

  @override
  List<Object?> get props => [];
}

class ConnectivityInitial extends ConnectivityState {}

class ConnectivityConnected extends ConnectivityState {
  final ConnectivityResult result;

  const ConnectivityConnected(this.result);

  @override
  List<Object?> get props => [result];
}

class ConnectivityDisconnected extends ConnectivityState {}

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  final Connectivity _connectivity = Connectivity();
  final StreamController<ConnectivityResult> _controller = StreamController<ConnectivityResult>.broadcast();

  factory ConnectivityService() => _instance;

  ConnectivityService._internal() {
    _connectivity.onConnectivityChanged.listen((result) {
      _controller.add(result.first); // Notify all listeners
    });
  }

  Stream<ConnectivityResult> get connectivityStream => _controller.stream;

  Future<List<ConnectivityResult>> checkConnectivity() async {
    return await _connectivity.checkConnectivity();
  }
}
