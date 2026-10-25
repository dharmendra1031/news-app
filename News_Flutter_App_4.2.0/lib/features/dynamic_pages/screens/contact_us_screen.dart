import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:news/commons/widgets/custom_appbar.dart';
import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/utils/ui_utils.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  // FIGMA(184-7372): Contact details shown on the Contact Us screen.
  // Replace these placeholder values with the app owner's real contact info.
  static const String _headOfficeNo = "+919876543210";
  static const String _faxNo = "+9195324785584";
  static const String _officeAddress = "Gujarat-India";
  static const String _emailAddress = "newsApp123@gmail.com";

  static Route route(RouteSettings routeSettings) {
    return CupertinoPageRoute(builder: (_) => const ContactUsScreen());
  }

  @override
  Widget build(BuildContext context) {
    final Color secondaryColor =
        UiUtils.getColorScheme(context).primaryContainer;
    return Scaffold(
      appBar: const CustomAppBar(
        height: 54,
        isBackBtn: true,
        label: 'contactUsLbl',
        isConvertText: true,
        horizontalPad: 16,
      ),
      body: SingleChildScrollView(
        padding:
            const EdgeInsetsDirectional.only(start: 16.0, end: 16.0, top: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // "How can we help you?" section (M3 title/medium + body/small)
            CustomTextLabel(
              text: 'howCanWeHelpLbl',
              textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: secondaryColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    height: 24 / 16,
                    letterSpacing: 0.15,
                  ),
            ),
            const SizedBox(height: 16),
            CustomTextLabel(
              text: 'contactHelpDescLbl',
              textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: secondaryColor,
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    height: 16 / 12,
                    letterSpacing: 0.4,
                  ),
            ),
            const SizedBox(height: 24),
            // Contact info sections (16px gap between each section)
            _contactInfoSection(
                context, 'headOfficeNoLbl', _headOfficeNo, secondaryColor),
            const SizedBox(height: 16),
            _contactInfoSection(context, 'faxNoLbl', _faxNo, secondaryColor),
            const SizedBox(height: 16),
            _contactInfoSection(
                context, 'officeAddressLbl', _officeAddress, secondaryColor),
            const SizedBox(height: 16),
            _contactInfoSection(
                context, 'emailAddressLbl', _emailAddress, secondaryColor),
          ],
        ),
      ),
    );
  }

  // A label (M3 title/small) stacked above its value (M3 body/medium) with a
  // 6px gap, matching the Figma "Contact Info Section".
  Widget _contactInfoSection(
      BuildContext context, String labelKey, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        CustomTextLabel(
          text: labelKey,
          textStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
                fontSize: 14,
                height: 20 / 14,
                letterSpacing: 0.1,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w400,
                fontSize: 14,
                height: 20 / 14,
                letterSpacing: 0.25,
              ),
        ),
      ],
    );
  }
}
