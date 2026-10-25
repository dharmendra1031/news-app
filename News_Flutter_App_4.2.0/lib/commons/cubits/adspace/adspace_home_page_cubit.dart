import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/commons/models/ad_space_model.dart';
import 'package:news/core/api/api.dart';
import 'package:news/core/constants/strings.dart';

abstract class AdSpaceHomePageState {}

class AdSpaceHomePageInitial extends AdSpaceHomePageState {}

class AdSpaceHomePageFetchInProgress extends AdSpaceHomePageState {}

class AdSpaceHomePageFetchSuccess extends AdSpaceHomePageState {
  final AdSpaceModel? adSpaceTopData;
  final AdSpaceModel? adSpaceBottomData;

  AdSpaceHomePageFetchSuccess({this.adSpaceTopData, this.adSpaceBottomData});
}

class AdSpaceHomePageFetchFailure extends AdSpaceHomePageState {
  final String errorMessage;

  AdSpaceHomePageFetchFailure(this.errorMessage);
}

class AdSpaceHomePageCubit extends Cubit<AdSpaceHomePageState> {
  AdSpaceHomePageCubit() : super(AdSpaceHomePageInitial());

  void getAdspaceForHomePage(
      {required String langCode, required String page}) async {
    emit(AdSpaceHomePageFetchInProgress());
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

      emit(AdSpaceHomePageFetchSuccess(
          adSpaceTopData: topData, adSpaceBottomData: bottomData));
    } catch (e) {
      emit(AdSpaceHomePageFetchFailure(e.toString()));
    }
  }
}
