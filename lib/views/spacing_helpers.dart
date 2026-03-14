import 'package:flutter/material.dart';

/// Contains useful consts to reduce boilerplate and duplicate code
class SpacingHelper {
  // Vertical spacing constants. Adjust to your liking.
  static const double _VerticalSpaceSm = 10.0;
  static const double _VerticalSpaceMd = 20.0;
  static const double _VerticalSpace30 = 30.0;
  static const double _VerticalSpaceL = 42.0;
  static const double _VerticalSpaceXL = 92.0;

  // Vertical spacing constants. Adjust to your liking.
  static const double _HorizontalSpaceSm = 10.0;
  static const double _HorizontalSpaceMd = 20.0;
  static const double _HorizontalSpaceL = 60.0;

  static const Widget verticalSpaceSm = SizedBox(height: _VerticalSpaceSm);
  static const Widget verticalSpaceMd = SizedBox(height: _VerticalSpaceMd);
  static const Widget verticalSpace30 = SizedBox(height: _VerticalSpace30);
  static const Widget verticalSpaceL = SizedBox(height: _VerticalSpaceL);
  static const Widget verticalSpaceXL = SizedBox(height: _VerticalSpaceXL);

  static const Widget horizontalSpaceSm = SizedBox(width: _HorizontalSpaceSm);
  static const Widget horizontalSpaceMd = SizedBox(width: _HorizontalSpaceMd);
  static const Widget horizontalSpaceL = SizedBox(width: _HorizontalSpaceL);
  static Size getScreenSize(context) {
    return MediaQuery.of(context).size;
  }

//todo modify the theme
/* static ThemeData darkTheme = ThemeData(
    primaryColor: Colors.black,
    backgroundColor: Colors.grey[700],
    brightness: Brightness.dark,
  );
  static ThemeData lightTheme = ThemeData(
    primaryColor: Colors.red,
    accentColor: Colors.red[400],
    backgroundColor: Colors.grey[200],
    brightness: Brightness.light,
  );*/
}
