import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:news/commons/widgets/custom_appbar.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyPolicy extends StatefulWidget {
  final String? title;
  final String? from;
  final String? desc;

  const PrivacyPolicy({super.key, this.title, this.from, this.desc});

  @override
  State<StatefulWidget> createState() {
    return StatePrivacy();
  }

  static Route route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
        builder: (_) => PrivacyPolicy(
              from: arguments['from'],
              title: arguments['title'],
              desc: arguments['desc'],
            ));
  }
}

class StatePrivacy extends State<PrivacyPolicy> with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: CustomAppBar(height: 45, isBackBtn: true, label: widget.title!, horizontalPad: 15, isConvertText: false),
        body: SingleChildScrollView(
          padding: const EdgeInsetsDirectional.only(start: 20.0, end: 20.0, top: 10.0),
          child: HtmlWidget(
            widget.desc!,
            onTapUrl: (String? url) async {
              if (await canLaunchUrl(Uri.parse(url!))) {
                await launchUrl(Uri.parse(url));
                return true;
              } else {
                throw 'Could not launch $url';
              }
            },
          ),
        ));
  }
}
