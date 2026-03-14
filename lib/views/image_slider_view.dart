import 'package:cached_network_image/cached_network_image.dart';
import 'package:deepinheart/views/photo_view_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_slideshow/flutter_image_slideshow.dart';
import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';

class ImageSliderView extends StatelessWidget {
  List<String>? listImages;
  ImageSliderView({Key? key, this.listImages}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: ImageSlideshow(
          width: double.infinity,
          height: Get.height * 0.35,
          initialPage: 0,
          indicatorColor: Colors.blue,
          indicatorBackgroundColor: Colors.grey,
          onPageChanged: (value) {
            // debugPrint('Page changed: $value');
          },
          autoPlayInterval: 7000,
          isLoop: true,
          children: listImages!.map((e) {
            return GestureDetector(
              onTap: () {
                Get.to(PhotoViewScreen(url: e));
              },
              child: CachedNetworkImage(
                imageUrl: e,
                fit: BoxFit.cover,
              ),
            );
          }).toList()),
    );
  }
}
