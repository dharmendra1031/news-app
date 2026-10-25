import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/core/configs/app_config.dart';
import 'package:news/features/homepage/models/feature_section_model.dart';
import 'package:news/features/homepage/repositories/featured_section/section_repository.dart';
import 'package:news/core/constants/strings.dart';

abstract class SectionState {}

class SectionInitial extends SectionState {}

class SectionFetchInProgress extends SectionState {}

class SectionFetchSuccess extends SectionState {
  final List<FeatureSectionModel> section;
  final int totalCount;
  final bool hasMoreFetchError;
  final bool hasMore;
  SectionFetchSuccess(
      {required this.section,
      required this.totalCount,
      required this.hasMore,
      required this.hasMoreFetchError});
}

class SectionFetchFailure extends SectionState {
  final String errorMessage;

  SectionFetchFailure(this.errorMessage);
}

class SectionCubit extends Cubit<SectionState> {
  final SectionRepository _sectionRepository;

  SectionCubit(this._sectionRepository) : super(SectionInitial());

  void getSection(
      {required String langCode, String? latitude, String? longitude}) async {
    try {
      emit(SectionFetchInProgress());
      final result = await _sectionRepository.getSection(
          langCode: langCode,
          latitude: latitude,
          longitude: longitude,
          limit: limitOfAPIData.toString(),
          offset: "0",
          sectionOffset: "0");
      (!result[ERROR])
          ? emit(SectionFetchSuccess(
              section: result['Section'],
              totalCount: result[TOTAL],
              hasMore: result['Section'].length < result[TOTAL],
              hasMoreFetchError: false,
            ))
          : emit(SectionFetchFailure(result[MESSAGE]));
    } catch (e) {
      emit(SectionFetchFailure(e.toString()));
    }
  }

  bool hasMoreSections() {
    return (state is SectionFetchSuccess)
        ? (state as SectionFetchSuccess).hasMore
        : false;
  }

  void getMoreSections(
      {required String langCode, String? latitude, String? longitude}) async {
    final current = state;
    if (current is SectionFetchSuccess) {
      try {
        final result = await _sectionRepository.getSection(
            langCode: langCode,
            latitude: latitude,
            longitude: longitude,
            limit: limitOfAPIData.toString(),
            offset: "0",
            sectionOffset: current.section.length.toString());
        // State changed while waiting (refresh / language change / another
        // load-more) - this page is stale, so drop it.
        if (!identical(state, current)) return;
        if (!result[ERROR]) {
          List<FeatureSectionModel> updatedResults = [
            ...current.section,
            ...(result['Section'] as List<FeatureSectionModel>),
          ];
          emit(SectionFetchSuccess(
              section: updatedResults,
              totalCount: result[TOTAL],
              hasMoreFetchError: false,
              hasMore: updatedResults.length < result[TOTAL]));
        } else {
          emit(SectionFetchFailure(result[MESSAGE]));
        }
      } catch (e) {
        if (!identical(state, current)) return;
        emit(SectionFetchSuccess(
            section: current.section,
            hasMoreFetchError: true,
            totalCount: current.totalCount,
            hasMore: current.hasMore));
      }
    }
  }
}
