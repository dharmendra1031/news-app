import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/core/theme/theme_colors.dart';
import 'package:news/commons/widgets/custom_back_btn.dart';
import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/commons/widgets/shimmer_news_list.dart';
import 'package:news/features/subcategory/widgets/category_shimmer.dart';
import 'package:news/features/subcategory/widgets/subcat_news_list.dart';
import 'package:news/utils/ui_utils.dart';
import 'package:news/features/category/cubits/subcategory_cubit.dart';
import 'package:news/features/language/cubits/app_localization_cubit.dart';
import 'package:news/commons/cubits/app_system_setting_cubit.dart';
import 'package:news/features/news/cubits/subcat_news_cubit.dart';
import 'package:news/features/category/repositories/subcat_news/subCatRepository.dart';

class SubCategoryScreen extends StatefulWidget {
  final String catId;
  final String catName;

  const SubCategoryScreen(
      {super.key, required this.catId, required this.catName});

  @override
  SubCategoryScreenState createState() => SubCategoryScreenState();

  static Route route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
        builder: (_) => SubCategoryScreen(
            catId: arguments['catId'], catName: arguments['catName']));
  }
}

class SubCategoryScreenState extends State<SubCategoryScreen>
    with TickerProviderStateMixin {
  final List<Map<String, dynamic>> _tabs = [];
  TabController? _tc;
  bool isSubcatExist = true;

  @override
  void initState() {
    getSubCatData();
    super.initState();
  }

  @override
  void dispose() {
    if (_tc != null) {
      _tc!.dispose();
    }
    super.dispose();
  }

  Future getSubCatData() async {
    Future.delayed(Duration.zero, () {
      context.read<SubCategoryCubit>().getSubCategory(
          context: context,
          langCode: context.read<AppLocalizationCubit>().state.languageCode,
          catId: widget.catId);
    });
  }

  Widget subcatData() {
    return BlocConsumer<SubCategoryCubit, SubCategoryState>(
        bloc: context.read<SubCategoryCubit>(),
        listener: (context, state) {
          if (state is SubCategoryFetchSuccess) {
            setState(() {
              for (int i = 0; i < state.subCategory.length; i++) {
                _tabs.add({
                  'text': state.subCategory[i].subCatName,
                  'subCatId': state.subCategory[i].id
                });
              }
              _tc = TabController(vsync: this, length: state.subCategory.length)
                ..addListener(() {});
            });
          }
          if (state is SubCategoryFetchFailure) {
            isSubcatExist = false;
            setState(() {});
          }
        },
        builder: (context, state) {
          if (state is SubCategoryFetchSuccess) {
            return DefaultTabController(
                length: state.subCategory.length,
                child: _tabs.isNotEmpty
                    ? TabBar(
                        controller: _tc,
                        labelColor: secondaryColor,
                        indicatorColor: Colors.transparent,
                        isScrollable: true,
                        padding: const EdgeInsets.only(
                            top: 10, bottom: 5, left: 3, right: 3),
                        physics: const AlwaysScrollableScrollPhysics(),
                        unselectedLabelColor:
                            UiUtils.getColorScheme(context).primaryContainer,
                        indicator: BoxDecoration(
                            borderRadius: BorderRadius.circular(5.0),
                            color: UiUtils.getColorScheme(context)
                                .secondaryContainer),
                        tabs: _tabs
                            .map((tab) => AnimatedContainer(
                                height: 30,
                                duration: const Duration(milliseconds: 600),
                                padding: const EdgeInsetsDirectional.only(
                                    top: 5.0, bottom: 5.0),
                                child: Tab(text: tab['text'])))
                            .toList())
                    : subcatShimmer());
          }
          if (state is SubCategoryFetchFailure) {
            return const SizedBox.shrink();
          }
          //state is SubCategoryFetchInProgress || state is SubCategoryInitial
          return subcatShimmer();
        });
  }

  setAppBar() {
    return PreferredSize(
        preferredSize: Size(double.infinity, (isSubcatExist) ? 100 : 56),
        child: UiUtils.applyBoxShadow(
          context: context,
          child: AppBar(
            leading: const CustomBackButton(horizontalPadding: 15),
            titleSpacing: 0.0,
            centerTitle: false,
            backgroundColor: Colors.transparent,
            title: CustomTextLabel(
                text: widget.catName,
                textStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: UiUtils.getColorScheme(context).primaryContainer,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5)),
            bottom: PreferredSize(
                preferredSize: Size(MediaQuery.of(context).size.width, 30),
                child: subcatData()),
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: setAppBar(),
      body: BlocBuilder<SubCategoryCubit, SubCategoryState>(
          builder: (context, state) {
        if (state is SubCategoryFetchFailure ||
            context.read<AppConfigurationCubit>().getSubCatMode() != "1") {
          return BlocProvider<SubCatNewsCubit>(
              create: (_) => SubCatNewsCubit(SubCatNewsRepository()),
              child: SubCatNewsList(from: 1, catId: widget.catId));
        }
        if (state is SubCategoryFetchSuccess &&
            _tc != null &&
            _tc!.length > 0) {
          return TabBarView(
              controller: _tc,
              children: List<Widget>.generate(_tc!.length, (int index) {
                return BlocProvider<SubCatNewsCubit>(
                    create: (_) => SubCatNewsCubit(SubCatNewsRepository()),
                    child: SubCatNewsList(
                        from: index == 0 ? 1 : 2,
                        subCatId: index == 0 ? null : _tabs[index]['subCatId'],
                        catId: widget.catId));
              }));
        }
        return ShimmerNewsList(isNews: true);
      }),
    );
  }
}
