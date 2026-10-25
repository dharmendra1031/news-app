import 'package:flutter/material.dart';
import 'package:news/commons/widgets/svg_picture_widget.dart';
import 'package:news/core/routes/routes.dart';
import 'package:news/core/theme/theme_colors.dart';
import 'package:news/utils/ui_utils.dart';
import 'package:news/commons/widgets/custom_text_label.dart';

class LiveWithSearchView extends StatelessWidget {
  const LiveWithSearchView({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color tertiaryColor =
        isDark ? textSecondaryColor : textTertiaryColor;

    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: 8.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(8.0),
        onTap: () => Navigator.of(context).pushNamed(Routes.search),
        child: Container(
          height: 47.0,
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 16.0),
          decoration: BoxDecoration(
            color: UiUtils.getColorScheme(context).surface,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color: isDark ? darkBorderDefaultColor : borderDefaultColor,
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              SvgPictureWidget(
                assetName: "search_status",
                height: 24.0,
                width: 24.0,
                assetColor: ColorFilter.mode(tertiaryColor, BlendMode.srcIn),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: CustomTextLabel(
                  text: 'searchHomeNews',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textStyle: TextStyle(
                    fontSize: 14.0,
                    height: 20 / 14,
                    fontWeight: FontWeight.w400,
                    color: tertiaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
