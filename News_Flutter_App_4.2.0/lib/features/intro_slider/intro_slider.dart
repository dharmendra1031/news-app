import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/commons/widgets/custom_text_btn.dart';
import 'package:news/commons/widgets/svg_picture_widget.dart';
import 'package:news/core/theme/theme_colors.dart';
import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/utils/ui_utils.dart';
import 'package:news/core/routes/routes.dart';
import 'package:news/commons/cubits/setting_cubit.dart';

class Slide {
  final String? imageUrl;
  final String? title;
  final String? description;

  Slide({
    @required this.imageUrl,
    @required this.title,
    @required this.description,
  });
}

// FIGMA(184-5787 / "Background"): the onboarding card is not a plain rounded
// rectangle - its sides taper inward toward the bottom (full width at the top,
// ~13px narrower each side at the bottom) with ~30px rounded corners. This is
// the exact Figma vector path (viewBox 356.492 x 584) scaled to the card rect,
// so the card matches the design while its bottom edge stays flat (keeping the
// red "Ellipse 234" glow flush beneath it).
class _OnboardingCardShape extends ShapeBorder {
  const _OnboardingCardShape();

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect, textDirection: textDirection);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final double sx = rect.width / 356.492;
    final double sy = rect.height / 584.0;
    double px(double x) => rect.left + x * sx;
    double py(double y) => rect.top + y * sy;
    return Path()
      ..moveTo(px(0.00880057), py(30.7189))
      ..cubicTo(
          px(-0.395023), py(13.8737), px(13.1501), py(0), px(30.0002), py(0))
      ..lineTo(px(326.492), py(0))
      ..cubicTo(px(343.362), py(0), px(356.915), py(13.9057), px(356.482),
          py(30.7703))
      ..lineTo(px(343.023), py(554.77))
      ..cubicTo(
          px(342.605), py(571.033), px(329.302), py(584), px(313.033), py(584))
      ..lineTo(px(42.5618), py(584))
      ..cubicTo(px(26.2734), py(584), px(12.9608), py(571.003), px(12.5704),
          py(554.719))
      ..lineTo(px(0.00880057), py(30.7189))
      ..close();
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => this;
}

class IntroSliderScreen extends StatefulWidget {
  const IntroSliderScreen({super.key});

  @override
  GettingStartedScreenState createState() => GettingStartedScreenState();
}

class GettingStartedScreenState extends State<IntroSliderScreen> {
  int currentIndex = 0;

  late final List<Slide> slideList = [
    Slide(
      imageUrl: 'onboarding1',
      title: UiUtils.getTranslatedLabel(context, 'welTitle1'),
      description: UiUtils.getTranslatedLabel(context, 'welDes1'),
    ),
    Slide(
      imageUrl: 'onboarding2',
      title: UiUtils.getTranslatedLabel(context, 'welTitle2'),
      description: UiUtils.getTranslatedLabel(context, 'welDes2'),
    ),
    Slide(
      imageUrl: 'onboarding3',
      title: UiUtils.getTranslatedLabel(context, 'welTitle3'),
      description: UiUtils.getTranslatedLabel(context, 'welDes3'),
    ),
  ];

  void gotoNext() {
    context.read<SettingsCubit>().changeShowIntroSlider(false);
    Navigator.of(context).pushReplacementNamed(Routes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: nextButton(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        centerTitle: false,
        actions: [setSkipButton()],
        title: SvgPictureWidget(assetName: "intro_icon", fit: BoxFit.cover),
      ),
      body: _buildIntroSlider(),
    );
  }

  Widget _buildIntroSlider() {
    final size = MediaQuery.of(context).size;
    final slide = slideList[currentIndex];

    return SizedBox(
        width: size.width,
        height: size.height * 0.75,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // FIGMA(184-5787 / "Ellipse 234"): the ONLY shadow in the design is
            // this soft red glow under the card. Reproduced EXACTLY from the
            // Figma SVG - an ellipse 155x12 filled #EE2934 @ 25% opacity with a
            // gaussian blur of stdDeviation 8. A BoxShadow can't reproduce the
            // soft radial falloff of a blurred ellipse, so we blur a REAL ellipse
            // with ui.ImageFilter.blur whose sigma == the SVG's stdDeviation.
            // The ellipse + sigma are scaled from the Figma card width (356.492)
            // to the actual card width (screen - 24px margins each side).
            Positioned(
              left: 0,
              right: 0,
              bottom: 14,
              child: Builder(builder: (context) {
                final double scale = (size.width - 48) / 356.492;
                final double w = 155 * scale;
                final double h = 12 * scale;
                return Center(
                  child: ImageFiltered(
                    imageFilter: ui.ImageFilter.blur(
                        sigmaX: 8 * scale, sigmaY: 8 * scale),
                    child: Container(
                      width: w,
                      height: h,
                      decoration: BoxDecoration(
                        // Exact Figma shadow colour: #EE2934 @ 25% (brand
                        // primary). NOT colorScheme.primary - fromSeed shifts it
                        // to a muted red.
                        color: primaryColor.withOpacity(0.25),
                        borderRadius:
                            BorderRadius.all(Radius.elliptical(w / 2, h / 2)),
                      ),
                    ),
                  ),
                );
              }),
            ),
            GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity == null) return;

                // Swipe Left -> Next
                if (details.primaryVelocity! < -100) {
                  if (currentIndex < slideList.length - 1) {
                    setState(() {
                      currentIndex++;
                    });
                  }
                }

                // Swipe Right -> Previous
                if (details.primaryVelocity! > 100) {
                  if (currentIndex > 0) {
                    setState(() {
                      currentIndex--;
                    });
                  }
                }
              },
              // FIGMA(184-5787 "Background"): the card uses the exact Figma
              // vector shape (see _OnboardingCardShape) so its sides taper in
              // toward the bottom, instead of the old rotateX 3D tilt that
              // foreshortened the card and mis-placed the red glow. The bottom
              // edge stays flat, so the "Ellipse 234" glow remains flush below.
              child: Container(
                margin: const EdgeInsets.fromLTRB(24, 30, 24, 20),
                clipBehavior: Clip.antiAlias,
                // FIGMA(184-5787): plain white fill, NO drop shadow of its own -
                // the design's only shadow is the soft red "Ellipse 234" glow
                // painted behind the card (see above).
                decoration: ShapeDecoration(
                  color: secondaryColor,
                  shape: const _OnboardingCardShape(),
                ),
                // The card content is split so that ONLY the image + texts
                // animate when sliding between pages. The slider dots are
                // pulled OUT of the AnimatedSwitcher (see below) so they stay
                // fixed and just switch the active dot (1 -> 2 -> 3) instead
                // of sliding along with the image.
                child: Column(
                  children: [
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.2, 0),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        // Only this sub-tree (image + title + subtitle) slides.
                        child: Column(
                          key: ValueKey(currentIndex),
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: slide.imageUrl != null
                                    ? SvgPictureWidget(
                                        assetName: slide.imageUrl!,
                                        fit: BoxFit.contain,
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ),
                            titleText(),
                            subtitleText(),
                          ],
                        ),
                      ),
                    ),
                    // FIGMA: dots are kept OUTSIDE the AnimatedSwitcher so they
                    // do NOT slide - only the active dot changes per page.
                    progressIndicator(),
                    const SizedBox(height: 25),
                  ],
                ),
              ),
            )
          ],
        ));
  }

  Widget setSkipButton() {
    return currentIndex != slideList.length - 1
        ? CustomTextButton(
            onTap: gotoNext,
            color: UiUtils.getColorScheme(context)
                .primaryContainer
                .withOpacity(0.7),
            text: UiUtils.getTranslatedLabel(context, 'skip'),
          )
        : const SizedBox.shrink();
  }

  Widget titleText() {
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 10),
      margin: const EdgeInsets.only(
        bottom: 20.0,
        left: 10,
        right: 10,
      ),
      alignment: Alignment.center,
      child: CustomTextLabel(
        text: slideList[currentIndex].title!,
        textStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: darkSecondaryColor,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
      ),
    );
  }

  Widget subtitleText() {
    return Container(
      padding: const EdgeInsets.only(left: 10),
      margin: const EdgeInsets.only(
        bottom: 55.0,
        left: 10,
        right: 10,
      ),
      child: CustomTextLabel(
        text: slideList[currentIndex].description!,
        textAlign: TextAlign.left,
        textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: darkSecondaryColor.withOpacity(0.5),
              fontWeight: FontWeight.normal,
              letterSpacing: 0.5,
            ),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget progressIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        slideList.length,
        (index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: InkWell(
            onTap: () {
              setState(() {
                currentIndex = index;
              });
            },
            child: currentIndex == index
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10.0),
                    child: Container(
                      height: 8,
                      width: 23,
                      color: darkSecondaryColor,
                    ),
                  )
                : CircleAvatar(
                    radius: 5,
                    backgroundColor: darkSecondaryColor.withOpacity(0.6),
                  ),
          ),
        ),
      ),
    );
  }

  Widget nextButton() {
    return MaterialButton(
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.35,
        vertical: 25,
      ),
      onPressed: () {
        if (currentIndex == slideList.length - 1) {
          gotoNext();
        } else {
          setState(() {
            currentIndex++;
          });
        }
      },
      child: Container(
        height: 34,
        width: 82,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(5),
        ),
        child: CustomTextLabel(
          text: currentIndex == slideList.length - 1 ? 'loginBtn' : 'nxt',
          textStyle: Theme.of(context).textTheme.bodyLarge!.copyWith(
                color: secondaryColor,
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
