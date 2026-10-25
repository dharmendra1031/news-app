import 'package:flutter/material.dart';
import 'package:news/commons/widgets/network_image.dart';
import 'package:news/core/routes/routes.dart';
import 'package:news/core/theme/theme_colors.dart';
import 'package:news/features/news/models/breaking_news_model.dart';
import 'package:news/features/news/models/news_model.dart';

class ImageView extends StatefulWidget {
  final NewsModel? model;
  final BreakingNewsModel? breakModel;
  final bool isFromBreak;

  const ImageView(
      {super.key, this.model, this.breakModel, required this.isFromBreak});

  @override
  ImageViewState createState() => ImageViewState();
}

class ImageViewState extends State<ImageView> {
  List<String> allImage = [];
  int _curSlider = 0;

  late final PageController _pageController;

  // static double _thumbSize = 60;
  // static double _thumbSpacing = 8;
  // static double _thumbPadding = 12;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    allImage.clear();
    if (!widget.isFromBreak) {
      allImage.add(widget.model!.image ?? "");
      if (widget.model!.imageDataList!.isNotEmpty) {
        for (int i = 0; i < widget.model!.imageDataList!.length; i++) {
          allImage.add(widget.model!.imageDataList![i].otherImage ?? "");
        }
      }
    } else {
      allImage.add(widget.breakModel!.image ?? "");
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget imageView() {
    final imageHeight = MediaQuery.of(context).size.height * 0.25;  

    return SizedBox(
      height: imageHeight,
      width: double.maxFinite,
      child: !widget.isFromBreak
          ? PageView.builder(
              controller: _pageController,
              itemCount: allImage.length,
              onPageChanged: (index) {
                setState(() {
                  _curSlider = index;
                });
              },
              itemBuilder: (context, index) {
                return InkWell(
                  onTap: () {
                    Navigator.of(context).pushNamed(
                      Routes.imagePreview,
                      arguments: {
                        "index": index,
                        "imgList": allImage,
                      },
                    );
                  },
                  child: CustomNetworkImage(
                    networkImageUrl: allImage[index],
                    width: double.infinity,
                    height: imageHeight,
                    fit: BoxFit.cover,
                    isVideo: false,
                  ),
                );
              },
            )
          : CustomNetworkImage(
              networkImageUrl: widget.breakModel!.image ?? "",
              width: double.infinity,
              height: imageHeight,
              isVideo: false,
              fit: BoxFit.cover),
    );
  }

  List<T> map<T>(List list, Function handler) {
    List<T> result = [];
    for (var i = 0; i < list.length; i++) {
      result.add(handler(i, list[i]));
    }

    return result;
  }

  Widget imageSliderDot() {
    // FIGMA(3768-8884 light / 3768-9010 dark): 8px dots, Background/Brand
    // (#E00000) for the active one and Icon/Disabled (#CECECE light, #676767
    // dark) for the rest, 8px apart, centered inside the image card.
    if (!widget.isFromBreak && allImage.length > 1) {
      final bool isDark = Theme.of(context).brightness == Brightness.dark;
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: map<Widget>(allImage, (index, url) {
          final bool active = _curSlider == index;
          return Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active
                  ? primaryColor
                  : (isDark ? textSecondaryColor : const Color(0xffCECECE)),
            ),
          );
        }),
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        imageView(),
        Positioned(bottom: 12, left: 0, right: 0, child: imageSliderDot()),
      ],
    );
  }
}
