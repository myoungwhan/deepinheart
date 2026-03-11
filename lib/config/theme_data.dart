import 'package:deepinheart/main.dart';
import 'package:deepinheart/views/colors.dart';
import 'package:flutter/material.dart';

class Themes {
  static final light = ThemeData.light().copyWith(
    colorScheme: ColorScheme.light(
      background: Colors.white,

      primary: primaryColor, // Primary color #246596
    ),
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: AppBarTheme(
      color: Colors.white, // Primary color for the app bar
      iconTheme: IconThemeData(
        color: Colors.black,
      ), // White icons in the app bar
    ),
    iconTheme: IconThemeData(color: Colors.white),
    buttonTheme: ButtonThemeData(
      buttonColor: primaryColor, // Primary button color
      textTheme:
          ButtonTextTheme
              .primary, // Ensures text color is appropriate for buttons
    ),
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(iconColor: WidgetStatePropertyAll(Colors.black)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor, // Primary color for elevated buttons
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: primaryColor),
      ),
      labelStyle: TextStyle(
        color: primaryColor, // Label text color
      ),
    ),
  );

  static final dark = ThemeData.dark().copyWith(
    colorScheme: ColorScheme.dark(
      background: Colors.black,
      primary: primaryColor, // Primary color #246596
    ),
    appBarTheme: AppBarTheme(
      color: Colors.black, // Primary color for the app bar
      iconTheme: IconThemeData(
        color: Colors.white,
      ), // White icons in the app bar
    ),
    buttonTheme: ButtonThemeData(
      buttonColor: primaryColor, // Primary button color
      textTheme:
          ButtonTextTheme
              .primary, // Ensures text color is appropriate for buttons
    ),
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(iconColor: WidgetStatePropertyAll(Colors.white)),
    ),
    iconTheme: IconThemeData(color: Colors.white),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor, // Primary color for elevated buttons
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: primaryColor),
      ),
      labelStyle: TextStyle(
        color: primaryColor, // Label text color
      ),
    ),
  );
}
