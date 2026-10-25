import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/commons/models/ad_space_model.dart';
import 'package:news/core/api/api.dart';
import 'package:news/core/constants/strings.dart';

abstract class AdSpacesNewsDetailsState {}

class AdSpacesNewsDetailsInitial extends AdSpacesNewsDetailsState {}

class AdSpacesNewsDetailsFetchInProgress extends AdSpacesNewsDetailsState {}

class AdSpacesNewsDetailsFetchSuccess extends AdSpacesNewsDetailsState {
  final AdSpaceModel? adSpaceTopData;
  final AdSpaceModel? adSpaceBottomData;

  AdSpacesNewsDetailsFetchSuccess(
      {this.adSpaceTopData, this.adSpaceBottomData});
}

class AdSpacesNewsDetailsFetchFailure extends AdSpacesNewsDetailsState {
  final String errorMessage;

  AdSpacesNewsDetailsFetchFailure(this.errorMessage);
}

class AdSpacesNewsDetailsCubit extends Cubit<AdSpacesNewsDetailsState> {
  AdSpacesNewsDetailsCubit() : super(AdSpacesNewsDetailsInitial());

  void getAdspaceForNewsDetails(
      {required String langCode, required String page}) async {
    emit(AdSpacesNewsDetailsFetchInProgress());
    try {
      final body = {LANGUAGE_CODE: langCode, PLATFORM: "app", PAGE: page};
      final Map<String, dynamic> result =
          await Api.sendApiRequest(body: body, url: Api.getAdsNewsDetailsApi);
      final List<dynamic> dataList = result[DATA] ?? [];

      AdSpaceModel? topData;
      AdSpaceModel? bottomData;

      for (final item in dataList) {
        if (item is! Map) continue;
        final placement = item['placement']?.toString() ?? '';
        if (placement.contains('top')) {
          topData = AdSpaceModel.fromJson(item);
        } else if (placement.contains('bottom')) {
          bottomData = AdSpaceModel.fromJson(item);
        }
      }

      emit(AdSpacesNewsDetailsFetchSuccess(
          adSpaceTopData: topData, adSpaceBottomData: bottomData));
    } catch (e) {
      emit(AdSpacesNewsDetailsFetchFailure(e.toString()));
    }
  }
}
