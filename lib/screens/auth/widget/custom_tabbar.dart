// lib/views/custom_tabbar.dart

import 'package:deepinheart/views/font_constants.dart';
import 'package:flutter/material.dart';
import 'package:deepinheart/views/colors.dart';
import 'package:deepinheart/views/text_styles.dart';
import 'package:deepinheart/views/ui_helpers.dart';

class CustomTabBar extends StatefulWidget {
  /// Labels for each tab
  final List<String> tabs;

  /// Which tab to select initially
  final int initialIndex;

  /// Called whenever the user taps a new tab
  final ValueChanged<int> onTabChanged;

  const CustomTabBar({
    Key? key,
    required this.tabs,
    this.initialIndex = 0,
    required this.onTabChanged,
  }) : super(key: key);

  @override
  _CustomTabBarState createState() => _CustomTabBarState();
}

class _CustomTabBarState extends State<CustomTabBar>
    with SingleTickerProviderStateMixin {
  late TabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TabController(
      length: widget.tabs.length,
      vsync: this,
      initialIndex: widget.initialIndex,
    )..addListener(() {
      if (_controller.indexIsChanging) {
        widget.onTabChanged(_controller.index);
      }
    });
  }

  @override
  void didUpdateWidget(covariant CustomTabBar old) {
    super.didUpdateWidget(old);
    if (old.initialIndex != widget.initialIndex) {
      _controller.index = widget.initialIndex;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xffEFF0F6),
        borderRadius: BorderRadius.circular(25),
      ),
      child: TabBar(
        controller: _controller,
        onTap: widget.onTabChanged,
        overlayColor: MaterialStateProperty.all(Colors.transparent),
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color: primaryColor,
        ),

        indicatorPadding: const EdgeInsets.symmetric(
          vertical: 5,
          horizontal: 5,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: primaryColor,
        labelStyle: textStyleRobotoRegular(
          fontSize: FontConstants.font_14,
          weight: FontWeightConstants.medium,
        ),
        dividerHeight: 0.0,
        unselectedLabelStyle: textStyleRobotoRegular(
          fontSize: FontConstants.font_14,
          weight: FontWeightConstants.medium,
        ),
        tabs: widget.tabs.map((label) => Tab(text: label)).toList(),
      ),
    );
  }
}
