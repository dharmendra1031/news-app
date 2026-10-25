import 'package:flutter/material.dart';
import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/features/add_edit_news/widgets/user_all_news.dart';
import 'package:news/features/add_edit_news/widgets/user_drafted_news.dart';
import 'package:news/features/authentication/cubits/auth_cubit.dart';
import 'package:news/features/add_edit_news/blocs/get_user_drafted_news_cubit.dart';
import 'package:news/commons/repositories/settings/settings_local_data_repository.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/features/add_edit_news/blocs/get_user_news_cubit.dart';
import 'package:news/core/routes/routes.dart';
import 'package:news/core/theme/theme_colors.dart';
import 'package:news/utils/ui_utils.dart';

class ManageUserNews extends StatefulWidget {
  const ManageUserNews({super.key});

  @override
  ManageUserNewsState createState() => ManageUserNewsState();
}

class ManageUserNewsState extends State<ManageUserNews>
    with TickerProviderStateMixin {
  late final TabController tabController =
      TabController(length: 2, vsync: this);
  late final ScrollController controller = ScrollController()
    ..addListener(hasMoreNewsScrollListener);
  late final ScrollController draftController = ScrollController()
    ..addListener(hasMoreDraftedNewsScrollListener);

  Set<String> get locationValue =>
      SettingsLocalDataRepository().getLocationCityValues();

  @override
  void initState() {
    getNews();
    getUserDraftedNews();
    super.initState();
  }

  @override
  void dispose() {
    tabController.dispose();
    controller.dispose();
    draftController.dispose();
    super.dispose();
  }

  void getUserDraftedNews() {
    context.read<GetUserDraftedNewsCubit>().getUserDraftedNews(
        userId: int.parse(context.read<AuthCubit>().getUserId()));
  }

  void getMoreDraftedNews() {
    context.read<GetUserDraftedNewsCubit>().getMoreUserDraftedNews(
        userId: int.parse(context.read<AuthCubit>().getUserId()));
  }

  void getNews() {
    context.read<GetUserNewsCubit>().getGetUserNews(
        latitude: locationValue.first, longitude: locationValue.last);
  }

  void getMoreNews() {
    context.read<GetUserNewsCubit>().getMoreGetUserNews(
        latitude: locationValue.first, longitude: locationValue.last);
  }

  void hasMoreNewsScrollListener() {
    if (controller.position.maxScrollExtent == controller.offset) {
      if (context.read<GetUserNewsCubit>().hasMoreGetUserNews()) {
        getMoreNews();
      } else {
        //debugPrint("No more News for this user");
      }
    }
  }

  void hasMoreDraftedNewsScrollListener() {
    if (draftController.position.maxScrollExtent == draftController.offset) {
      if (context.read<GetUserDraftedNewsCubit>().hasMoreGetUserDraftedNews()) {
        getMoreDraftedNews();
      } else {
        //debugPrint("No more Drafted News for this user");
      }
    }
  }

  getAppBar() {
    return PreferredSize(
        preferredSize: const Size(double.infinity, 54),
        child: UiUtils.applyBoxShadow(
          context: context,
          child: AppBar(
            toolbarHeight: 54,
            centerTitle: false,
            backgroundColor: Colors.transparent,
            // Figma: 16px start inset, 24px icon, 12px gap, then the title.
            leadingWidth: 40,
            titleSpacing: 12,
            title: CustomTextLabel(
                text: 'manageNewsLbl',
                textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: UiUtils.getColorScheme(context).primaryContainer,
                    fontSize: 16,
                    height: 24 / 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.15)),
            leading: Padding(
              padding: const EdgeInsetsDirectional.only(start: 16.0),
              child: InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  child: Icon(Icons.arrow_back,
                      size: 24,
                      color: UiUtils.getColorScheme(context).primaryContainer)),
            ),
          ),
        ));
  }

  /// Segmented control from the Figma "Tab Container": a 6px-padded surface
  /// card holding two equal tabs separated by a 10px gap, the active one
  /// filled with the secondary colour.
  Widget newsTabBar() {
    return Container(
      margin: const EdgeInsetsDirectional.only(start: 16, end: 16),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: UiUtils.getColorScheme(context).surface),
      child: AnimatedBuilder(
        animation: tabController.animation!,
        builder: (context, _) {
          final int selected = tabController.animation!.value.round();
          return Row(children: [
            Expanded(child: newsTab('manageNewsAllLbl', 0, selected)),
            const SizedBox(width: 10),
            Expanded(child: newsTab('manageNewsDraftLbl', 1, selected)),
          ]);
        },
      ),
    );
  }

  Widget newsTab(String labelKey, int index, int selectedIndex) {
    final bool isSelected = index == selectedIndex;
    return InkWell(
      onTap: () => tabController.animateTo(index),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isSelected
                ? UiUtils.getColorScheme(context).primaryContainer
                : Colors.transparent),
        child: CustomTextLabel(
            text: labelKey,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            textStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: isSelected
                    ? UiUtils.getColorScheme(context).surface
                    : UiUtils.getColorScheme(context).primaryContainer)),
      ),
    );
  }

  /// Create News now lives here instead of on the profile list. It uses the
  /// same full-width bottom button as ManagePref's save button so the two
  /// screens read the same.
  Widget newsAddBtn() {
    return InkWell(
        onTap: () {
          Navigator.of(context).pushNamed(Routes.addNews,
              arguments: {"isEdit": false, "from": "myNews"});
        },
        child: Container(
          height: 40.0,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(4.0)),
          child: CustomTextLabel(
              text: 'createNewsLbl',
              textStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: secondaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 18)),
        ));
  }

  contentShimmer(BuildContext context) {
    return Shimmer.fromColors(
        baseColor: Colors.grey.withOpacity(0.6),
        highlightColor: Colors.grey,
        child: ListView.builder(
            shrinkWrap: true,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsetsDirectional.only(start: 20, end: 20),
            itemBuilder: (_, i) => Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    color: Colors.grey.withOpacity(0.6)),
                margin: const EdgeInsets.only(top: 20),
                height: 190.0),
            itemCount: 6));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getAppBar(),
      body: Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: Column(
          children: [
            newsTabBar(),
            Expanded(
              child: TabBarView(
                controller: tabController,
                children: [
                  UserAllNewsTab(
                      controller: controller,
                      contentShimmer: contentShimmer(context),
                      fetchNews: getNews,
                      fetchMoreNews: getMoreNews),
                  UserDraftedNewsTab(
                      controller: draftController,
                      contentShimmer: contentShimmer(context),
                      fetchDraftedNews: getUserDraftedNews,
                      fetchMoreDraftedNews: getMoreDraftedNews),
                ],
              ),
            ),
            SafeArea(
              top: false,
              bottom: false,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(
                    start: 16.0, end: 16.0, top: 8, bottom: 8),
                child: newsAddBtn(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
