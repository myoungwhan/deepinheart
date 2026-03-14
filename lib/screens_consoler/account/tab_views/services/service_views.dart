import 'package:auto_size_text/auto_size_text.dart';
import 'package:deepinheart/Controller/Viewmodel/userviewmodel.dart';
import 'package:deepinheart/screens_consoler/account/tab_views/services/tabview/add_fortuneservice_tabview.dart';
import 'package:deepinheart/views/colors.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:deepinheart/views/text_styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class ServiceViews extends StatefulWidget {
  const ServiceViews({Key? key}) : super(key: key);

  @override
  _ServiceViewsState createState() => _ServiceViewsState();
}

class _ServiceViewsState extends State<ServiceViews>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  List<String> listTags = ["Fortune", "Psychology"];

  // Cache tab views to prevent rebuilding
  late final List<Widget> _cachedTabViews;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: listTags.length,
      vsync: this,
      initialIndex: 0,
    );

    // Pre-cache tab views with lazy loading
    _cachedTabViews = [
      _LazyTabView(isFortune: true),
      _LazyTabView(isFortune: false),
    ];
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: Get.width,
      height: Get.height,
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            automaticIndicatorColorAdjustment: true,
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: primaryColorConsulor,
            isScrollable: false,
            tabAlignment: TabAlignment.fill,
            unselectedLabelColor: Colors.grey,
            indicatorColor: primaryColorConsulor,
            dividerColor: borderColor,
            indicatorWeight: 2,
            labelStyle: textStyleRobotoRegular(
              weight: FontWeightConstants.medium,
              fontSize: FontConstants.font_14,
            ),
            unselectedLabelStyle: textStyleRobotoRegular(
              weight: FontWeightConstants.medium,
              fontSize: FontConstants.font_14,
            ),
            tabs: [
              for (var tag in listTags)
                Tab(
                  child: AutoSizeText(
                    tag.tr,
                    textAlign: TextAlign.center,
                    maxFontSize: 14.0,
                    minFontSize: 14,
                  ),
                ),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: _cachedTabViews,
            ),
          ),
        ],
      ),
    );
  }
}

// Lazy loading wrapper for tab views
class _LazyTabView extends StatefulWidget {
  final bool isFortune;

  const _LazyTabView({Key? key, required this.isFortune}) : super(key: key);

  @override
  _LazyTabViewState createState() => _LazyTabViewState();
}

class _LazyTabViewState extends State<_LazyTabView> {
  Widget? _cachedWidget;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Delay initialization to improve initial load performance
    final userViewModel = Provider.of<UserViewModel>(context, listen: false);
    userViewModel.fetchTimeSlots();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeWidget();
      }
    });
  }

  void _initializeWidget() {
    if (!_isInitialized) {
      setState(() {
        _cachedWidget = AddFortuneserviceTabview(isFrotune: widget.isFortune);
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while initializing
    if (!_isInitialized || _cachedWidget == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return _cachedWidget!;
  }
}
