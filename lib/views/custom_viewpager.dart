import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:deepinheart/views/colors.dart';
import 'package:deepinheart/views/text_styles.dart';

class CustomViewPager extends StatefulWidget {
  List<Widget>? listViews;
  List<String>? listTags;
  var initIndex;
  var scrollAble;
  CustomViewPager(
      {Key? key,
      this.listTags,
      this.listViews,
      this.initIndex,
      this.scrollAble})
      : super(key: key);

  @override
  _CustomViewPagerState createState() => _CustomViewPagerState();
}

class _CustomViewPagerState extends State<CustomViewPager>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;

  @override
  void initState() {
    _tabController = TabController(
        length: widget.listTags!.length,
        vsync: this,
        initialIndex: widget.initIndex ?? 0);

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _tabController!.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = screenSize(context);
    return Padding(
      padding: const EdgeInsets.all(0.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // give the tab bar a height [can change hheight to preferred height]

          widget.scrollAble != null ? scrollAbleTags() : nonscrollAbleTags(),

          // tab bar view here
          Expanded(
            child: TabBarView(
              //    physics: NeverScrollableScrollPhysics(),

              controller: _tabController,
              children: widget.listViews!,
            ),
          ),
        ],
      ),
    );
  }

  SizedBox scrollAbleTags() {
    return SizedBox(
      height: 60.0,
      child: SingleChildScrollView(
        // Wrap TabBar with SingleChildScrollView
        scrollDirection: Axis.horizontal, // Horizontal scrolling
        child: TabBar(
          controller: _tabController,
          dividerHeight: 0.0,

          isScrollable: true, // Enable scrolling
          indicatorSize: TabBarIndicatorSize.tab,

          automaticIndicatorColorAdjustment: false,
          // give the indicator a decoration (color and border radius)
          indicator: BoxDecoration(
            boxShadow: [
              // BoxShadow(
              //     color: Color.fromRGBO(
              //         0, 0, 0, 0.30000000149011612),
              //     offset: Offset(0, 10),
              //     blurRadius: 5)
            ],
            borderRadius: BorderRadius.circular(
              10.0,
            ),
            color: primaryColor,
          ),

          indicatorPadding: EdgeInsets.symmetric(vertical: 5, horizontal: 5),
          labelColor: Colors.white,
          indicatorColor: Colors.grey,

          labelStyle: textStylemontserratRegular(
              fontSize: 13.0, weight: fontWeightSemiBold),
          unselectedLabelColor: Colors.grey,
          unselectedLabelStyle: textStylemontserratRegular(
            fontSize: 14.0,
            weight: fontWeightSemiBold,
          ),

          tabs: [
            // first tab [you can add an icon using the icon property]
            for (var tag in widget.listTags ?? [])
              Tab(
                text: tag.toString().tr,
              ),

            // second tab [you can add an icon using the icon property]
          ],
        ),
      ),
    );
  }

  SizedBox nonscrollAbleTags() {
    return SizedBox(
      // height: 50.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: TabBar(
          controller: _tabController,
          dividerHeight: 0.0,

          isScrollable: false, // Enable scrolling
          indicatorSize: TabBarIndicatorSize.tab,

          automaticIndicatorColorAdjustment: false,
          // give the indicator a decoration (color and border radius)
          indicator: BoxDecoration(
            boxShadow: [
              // BoxShadow(
              //     color: Color.fromRGBO(
              //         0, 0, 0, 0.30000000149011612),
              //     offset: Offset(0, 10),
              //     blurRadius: 5)
            ],
            borderRadius: BorderRadius.circular(
              10.0,
            ),
            color: primaryColor,
          ),

          indicatorPadding: EdgeInsets.symmetric(vertical: 5, horizontal: 5),
          labelColor: Colors.white,
          indicatorColor: Colors.grey,

          labelStyle: textStylemontserratRegular(
              fontSize: 13.0, weight: fontWeightSemiBold),
          unselectedLabelColor: Colors.grey,
          unselectedLabelStyle: textStylemontserratRegular(
            fontSize: 14.0,
            weight: fontWeightSemiBold,
          ),

          tabs: [
            // first tab [you can add an icon using the icon property]
            for (var tag in widget.listTags ?? [])
              Tab(
                text: tag.toString().tr,
              ),

            // second tab [you can add an icon using the icon property]
          ],
        ),
      ),
    );
  }
}
