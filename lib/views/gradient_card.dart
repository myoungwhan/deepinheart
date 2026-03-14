import 'package:flutter/material.dart';

import 'colors.dart';

class CustomGradientCard extends StatelessWidget {
  Widget? child;
  var color;
  var radius;
  var elevation;
  var onTap;

  CustomGradientCard(
      {Key? key,
      this.child,
      this.color,
      this.elevation,
      this.radius,
      this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation ?? 5,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius ?? 25)),
      child: Container(
        decoration: BoxDecoration(
          color: color ?? primaryColor,
          borderRadius: BorderRadius.circular(radius ?? 25),
          gradient: LinearGradient(
            colors: [
              color == Colors.white ? color : Colors.orange,

              color == Colors.white ? color : primaryColor,
              color == Colors.white ? color : Colors.orange,

              //  Colors.yellow.shade300,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          highlightColor: Colors.green,
          child: child,
        ),
      ),
    );
  }
}
