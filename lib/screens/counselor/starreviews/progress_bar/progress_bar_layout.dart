import 'package:flutter/material.dart';

import 'progress_bar.dart';

class ProgressBarLayout extends StatelessWidget {
  final String starName;
  final TextStyle starNameStyle;
  final TextStyle percentageStyle;
  final bool showPercentage;

  final Color valueColor;
  final Color progressBarBackgroundColor;
  final double value;

  final bool showBorder;
  final double lineHeight;

  ProgressBarLayout({
    Key? key,
    required this.starName,
    this.lineHeight = 5,
    this.showBorder = true,
    this.showPercentage = true,
    this.starNameStyle = const TextStyle(fontSize: 12),
    this.percentageStyle = const TextStyle(fontSize: 12),
    this.valueColor = const Color(0xff656565),
    this.progressBarBackgroundColor = Colors.white,
    required this.value,
  }) : super(key: key) {
    if (value == null) {
      throw ArgumentError('value cannot be empty');
    }

    if (starName == null) {
      throw ArgumentError('starName cannot be empty');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Text(this.starName, style: this.starNameStyle),

          // Row(
          //   mainAxisAlignment: MainAxisAlignment.end,
          //   children: List.generate(
          //       int.parse(this.starName),
          //       (index) => Icon(
          //             Icons.star,
          //             size: 15.0,
          //             color: orangeColor,
          //           )),
          // ),
          SizedBox(width: 20),
          Expanded(
            child: ProgressBar(
              lineHeight: this.lineHeight,
              showBorder: this.showBorder,
              value: this.value,
              valueColor: this.valueColor,
              backgroundColor: this.progressBarBackgroundColor,
            ),
          ),
          Visibility(
            visible: this.showPercentage,
            child: Row(
              children: <Widget>[
                SizedBox(width: 20),
                Text(
                  this.value.isInfinite || this.value.isNaN
                      ? "0%"
                      : (this.value * 100).toInt().toString() + '%',
                  style: this.percentageStyle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
