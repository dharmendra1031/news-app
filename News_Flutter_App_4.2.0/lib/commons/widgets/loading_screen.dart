import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/core/deep_link/reels_native_deep_link.dart';
import 'package:news/core/deep_link/share_deep_link.dart';
import 'package:news/features/language/cubits/language_cubit.dart';

class LoadingScreen extends StatefulWidget {
  String routeSettingsName;
  String newsSlug;

  LoadingScreen(
      {required this.routeSettingsName, required this.newsSlug, Key? key})
      : super(key: key);

  @override
  _LoadingScreenState createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  ValueNotifier<bool> isLoading = ValueNotifier(true);

  @override
  void initState() {
    super.initState();

    context.read<LanguageCubit>().getLanguage().then(
      (value) {
        fetchData();
      },
    );
    isLoading.addListener(() {
      if (!isLoading.value) {
        Navigator.pop(context);
      }
    });
  }

  Future<void> fetchData() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final path = ShareDeepLink.isReelsPath(widget.routeSettingsName)
        ? ShareDeepLink.resolveRouteName(widget.routeSettingsName)
        : widget.routeSettingsName;
    final slug = widget.newsSlug.trim().isNotEmpty
        ? widget.newsSlug.trim()
        : (ShareDeepLink.parseSlug(path) ??
            ShareDeepLink.parseSlug(ReelsNativeDeepLink.cachedFullUrl ?? '') ??
            '');

    await ShareDeepLinkHandler.handle(
      context,
      path: path,
      slug: slug,
      loadingNotifier: isLoading,
      usePopAndPushForNews: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
        valueListenable: isLoading,
        builder: (context, value, child) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        });
  }
}
