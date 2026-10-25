import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerNewsList extends StatelessWidget {
  bool isNews = true;

  ShimmerNewsList({Key? key, required this.isNews}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    //videos,Subcategory,Bookmarks & TagsPage
    return Shimmer.fromColors(
        baseColor: Colors.grey.withOpacity(0.6),
        highlightColor: Colors.grey,
        child: SingleChildScrollView(
          padding: const EdgeInsetsDirectional.only(top: 0.0),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const AlwaysScrollableScrollPhysics(),
            itemBuilder: (_, i) => Padding(
                padding: EdgeInsetsDirectional.only(top: i == 0 ? 0 : 15.0),
                child: Padding(
                  padding: EdgeInsetsDirectional.only(top: MediaQuery.of(context).size.height / 35.0, start: 15.0, end: 15.0),
                  child: Stack(
                    children: [
                      ClipRRect(
                          borderRadius: BorderRadius.circular(10.0),
                          child: Container(
                            height: MediaQuery.of(context).size.height / 4.2,
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10.0), color: Colors.grey.withOpacity(0.6)),
                          )),
                      (!isNews)
                          ? const SizedBox.shrink()
                          : Positioned.directional(
                              textDirection: Directionality.of(context),
                              bottom: 10.0,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: MediaQuery.of(context).size.width / 1.15,
                                    height: 10.0,
                                    margin: const EdgeInsetsDirectional.only(top: 4.0, start: 5.0, end: 5.0),
                                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(10.0), color: Colors.grey.withOpacity(0.6)),
                                  ),
                                  Container(
                                    width: MediaQuery.of(context).size.width / 2.0,
                                    height: 10.0,
                                    margin: const EdgeInsetsDirectional.only(top: 4.0, start: 5.0, end: 5.0),
                                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(10.0), color: Colors.grey.withOpacity(0.6)),
                                  ),
                                ],
                              ),
                            ),
                    ],
                  ),
                )),
            itemCount: 6,
          ),
        ));
  }
}

Widget iconButtons({required BuildContext context}) {
  return Container(
    width: MediaQuery.of(context).size.width / 20.0,
    height: 20.0,
    padding: const EdgeInsetsDirectional.only(top: 4.0, start: 5.0, end: 5.0),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(15.0), color: Colors.grey.withOpacity(0.6)),
  );
}
