import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LogoAnimatedLoading extends StatefulWidget {
  const LogoAnimatedLoading({super.key, this.size, this.color});

  final double? size;
  final Color? color;

  @override
  State<LogoAnimatedLoading> createState() => _LogoAnimatedLoadingState();
}

class _LogoAnimatedLoadingState extends State<LogoAnimatedLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final _tween = Tween<double>(begin: 0.9, end: 1);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.size ?? 90,
      width: widget.size ?? 90,
      child: ScaleTransition(
        scale: _tween.animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInBack),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(10.0),
            boxShadow: [
              // BoxShadow(
              //   color: Colors.black.withOpacity(0.2), // shadow color
              //   spreadRadius: 3, // how much the shadow spreads
              //   blurRadius: 6, // how blurred the shadow is
              //   offset: const Offset(0, 4), // position of the shadow
              // ),
            ],
          ),
          //  child: CircularProgressIndicator(),
          child: Image.asset(
            'images/simplelogo.png',
            //   color: widget.color ?? Theme.of(context).primaryColorLight,
          ).paddingAll(10),
        ),
      ),
    );
  }
}
