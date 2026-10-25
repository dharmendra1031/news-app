import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:news/core/theme/theme_colors.dart';
import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/commons/widgets/error_container_widget.dart';
import 'package:news/commons/widgets/network_image.dart';
import 'package:news/core/error_handler/error_message_keys.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:xml2json/xml2json.dart';
import 'dart:convert';

class RSSFeedDetailsScreen extends StatefulWidget {
  String feedUrl;

  RSSFeedDetailsScreen({Key? key, required this.feedUrl}) : super(key: key);

  @override
  _RSSFeedDetailsScreenState createState() => _RSSFeedDetailsScreenState();
  static Route route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
        builder: (_) => RSSFeedDetailsScreen(feedUrl: arguments['feedUrl']));
  }
}

class _RSSFeedDetailsScreenState extends State<RSSFeedDetailsScreen> {
  List<dynamic> _feedItems = [];
  bool isFeedLoaded = false;

  @override
  void initState() {
    super.initState();
    fetchFeed();
  }

  Widget buildFeedItem(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () => _launchURL(item['link'] ?? ''),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(8.0),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ((item.containsKey('image') && item['image'] != null) ||
                      (item.containsKey('url') && item['image']['url'] != null))
                  ? Padding(
                      padding: const EdgeInsetsDirectional.only(end: 10.0),
                      child: CustomNetworkImage(
                          networkImageUrl: (item['image'] != null)
                              ? item['image']
                              : item['image']['url'],
                          height: MediaQuery.of(context).size.height * 0.13,
                          width: MediaQuery.of(context).size.width * 0.23,
                          fit: BoxFit.cover),
                    )
                  : SizedBox.shrink(),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTextLabel(
                        text: item['title'] ?? 'No Title',
                        maxLines: 2,
                        textStyle: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    SizedBox(height: 8),
                    CustomTextLabel(
                        text: item['description'] ?? 'No Description',
                        maxLines: 3,
                        textStyle: TextStyle(color: borderColor)),
                    SizedBox(height: 8),
                    CustomTextLabel(
                        text: item['pubDate'] ?? 'Unknown Date',
                        textStyle:
                            TextStyle(fontSize: 12, color: Colors.grey[500]))
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.inAppBrowserView);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<void> fetchFeed() async {
    final url = widget.feedUrl;
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final xml2json = Xml2Json();
        xml2json.parse(response.body);

        final jsonString = xml2json.toParker();
        final jsonData = jsonDecode(jsonString);

        _feedItems = jsonData['rss']['channel']['item'] ?? [];
      } else {
        throw Exception('Failed to load feed');
      }
    } catch (e) {
      //print('Error: $e');
    }
    isFeedLoaded = true;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
          onRefresh: fetchFeed,
          child: !isFeedLoaded
              ? Center(child: CircularProgressIndicator())
              : _feedItems.isEmpty
                  ? ErrorContainerWidget(
                      errorMsg: ErrorMessageKeys.noDataMessage,
                      onRetry: fetchFeed)
                  : ListView.builder(
                      itemCount: _feedItems.length,
                      itemBuilder: (context, index) {
                        return buildFeedItem(_feedItems[index]);
                      },
                    )),
    );
  }
}
