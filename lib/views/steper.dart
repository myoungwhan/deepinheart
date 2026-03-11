// ignore_for_file: prefer_const_constructors, unnecessary_new

import 'package:flutter/material.dart';
import 'package:deepinheart/views/colors.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/ui_helpers.dart';

class StepProgressView extends StatelessWidget {
  final double _width;

  final List<String> _titles;
  final int _curStep;
  final Color _activeColor;
  final Color _inactiveColor = Colors.grey.shade300;
  final double lineWidth = 3.0;

  StepProgressView(
      {Key? key,
      @required int? curStep,
      List<String>? titles,
      @required double? width,
      @required Color? color})
      : _titles = titles!,
        _curStep = curStep!,
        _width = width!,
        _activeColor = color!,
        assert(width > 0),
        super(key: key);

  Widget build(BuildContext context) {
    return Container(
        // color: Colors.red,
        width: this._width,
        child: Column(
          children: <Widget>[
            Row(
              children: _iconViews(),
            ),
            UIHelper.verticalSpaceSm,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _titleViews(),
            ),
          ],
        ));
  }

  List<Widget> _iconViews() {
    var list = <Widget>[];
    _titles.asMap().forEach((i, icon) {
      var circleColor =
          (_curStep == i || _curStep > i) ? _activeColor : _inactiveColor;
      var lineColor = (_curStep > i) ? _activeColor : _inactiveColor;
      var iconColor =
          (_curStep == i || _curStep > i) ? whiteColor : Colors.black;
      bool isActive = i == _curStep;
      list.add(
        Container(
          width: 23.0,
          height: 23.0,
          padding: EdgeInsets.all(0),
          decoration: new BoxDecoration(
            /* color: circleColor,*/
            color: circleColor,
            borderRadius: new BorderRadius.all(new Radius.circular(22.0)),
            border: new Border.all(
              color: circleColor,
              width: 2.0,
            ),
          ),
          child: Center(
              child: CustomText(
            text: (i + 1).toString(),
            color: iconColor,
          )),
        ),
      );

      //line between icons
      if (i != _titles.length - 1) {
        list.add(Expanded(
            child: Container(
          height: lineWidth,
          color: lineColor,
        )));
      }
    });

    return list;
  }

  List<Widget> _titleViews() {
    var list = <Widget>[];
    _titles.asMap().forEach((i, text) {
      var circleColor =
          (_curStep == i || _curStep > i) ? _activeColor : _inactiveColor;

      var lineColor = _curStep > i + 1 ? _activeColor : _inactiveColor;
      var iconColor =
          (i == 0 || _curStep > i + 1) ? _activeColor : _inactiveColor;
      list.add(CustomText(
        text: text,
        fontSize: 10.0,
        isSemibold: true,
        align: TextAlign.start,
        color: circleColor,
      ));
    });
    return list;
  }
}
