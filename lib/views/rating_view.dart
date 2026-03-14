import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:deepinheart/views/colors.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/ui_helpers.dart';

class MyRatingView extends StatefulWidget {
  var initialRating;
  var itemSize;
  Function(double)? onRatingUpdate;
  var isAllowRating;
  var text;
  var fsize;
  int startQuantity;
  MyRatingView({
    super.key,
    this.initialRating,
    this.itemSize,
    this.onRatingUpdate,
    this.isAllowRating,
    this.fsize,
    this.text,
    this.startQuantity = 5,
  });

  @override
  State<MyRatingView> createState() => _MyRatingViewState();
}

class _MyRatingViewState extends State<MyRatingView> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        RatingBar.builder(
          initialRating: widget.initialRating ?? 0,
          //minRating: user.rating+.0,
          direction: Axis.horizontal,
          allowHalfRating: true,
          itemCount: widget.startQuantity,
          ignoreGestures: widget.isAllowRating ?? true,

          // updateOnDrag: widget.onRatingUpdate == null ? false : true,
          itemPadding: EdgeInsets.symmetric(horizontal: 1.0),

          itemSize: widget.itemSize ?? 18.0,
          itemBuilder: (context, _) => Icon(Icons.star, color: Colors.amber),
          onRatingUpdate: widget.onRatingUpdate ?? (val) {},
        ),
        UIHelper.horizontalSpaceSm5,
        widget.text != null
            ? CustomText(
              text: widget.text,
              color: hintColor,
              fontSize: widget.fsize,
            )
            : Container(),
      ],
    );
  }
}
