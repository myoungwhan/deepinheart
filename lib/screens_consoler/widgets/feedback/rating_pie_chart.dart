import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../models/feedback_data.dart';

class RatingPieChart extends StatefulWidget {
  final RatingDistribution distribution;

  const RatingPieChart({Key? key, required this.distribution})
    : super(key: key);

  // Colors for each rating level
  static const List<Color> ratingColors = [
    Color(0xFF4CAF50), // 5 stars - Green
    Color(0xFF8BC34A), // 4 stars - Light Green
    Color(0xFFFFC107), // 3 stars - Amber
    Color(0xFFFF9800), // 2 stars - Orange
    Color(0xFFF44336), // 1 star - Red
  ];

  // Labels for each rating
  static const List<String> ratingLabels = [
    '5 Stars',
    '4 Stars',
    '3 Stars',
    '2 Stars',
    '1 Star',
  ];

  @override
  State<RatingPieChart> createState() => _RatingPieChartState();
}

class _RatingPieChartState extends State<RatingPieChart> {
  int touchedIndex = -1;

  // Get filtered section data
  List<Map<String, dynamic>> get _sectionData {
    final d = widget.distribution;
    final data = [
      {
        'label': '5★',
        'fullLabel': '5 Stars',
        'count': d.fiveStar,
        'color': RatingPieChart.ratingColors[0],
        'stars': 5,
      },
      {
        'label': '4★',
        'fullLabel': '4 Stars',
        'count': d.fourStar,
        'color': RatingPieChart.ratingColors[1],
        'stars': 4,
      },
      {
        'label': '3★',
        'fullLabel': '3 Stars',
        'count': d.threeStar,
        'color': RatingPieChart.ratingColors[2],
        'stars': 3,
      },
      {
        'label': '2★',
        'fullLabel': '2 Stars',
        'count': d.twoStar,
        'color': RatingPieChart.ratingColors[3],
        'stars': 2,
      },
      {
        'label': '1★',
        'fullLabel': '1 Star',
        'count': d.oneStar,
        'color': RatingPieChart.ratingColors[4],
        'stars': 1,
      },
    ];
    return data.where((e) => (e['count'] as int) > 0).toList();
  }

  @override
  Widget build(BuildContext context) {
    final sections = _buildSections(widget.distribution);

    return SizedBox(
      height: 180.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pie Chart
          PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 45.r,
              sectionsSpace: 2,
              centerSpaceColor: Colors.transparent,
              titleSunbeamLayout: false,
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  if (event is FlTapUpEvent) {
                    setState(() {
                      if (pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        touchedIndex = -1;
                        return;
                      }
                      final tappedIndex =
                          pieTouchResponse.touchedSection!.touchedSectionIndex;
                      if (touchedIndex == tappedIndex) {
                        touchedIndex = -1;
                      } else {
                        touchedIndex = tappedIndex;
                      }
                    });
                  }
                },
              ),
            ),
            swapAnimationDuration: const Duration(milliseconds: 250),
            swapAnimationCurve: Curves.easeInOut,
          ),

          // Center Content
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: animation, child: child),
              );
            },
            child: _buildCenterContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterContent() {
    final data = _sectionData;
    final isSelected = touchedIndex >= 0 && touchedIndex < data.length;

    if (isSelected) {
      // Show selected section info
      final selectedData = data[touchedIndex];
      final count = selectedData['count'] as int;
      final color = selectedData['color'] as Color;
      final stars = selectedData['stars'] as int;
      final percentage =
          widget.distribution.total > 0
              ? (count / widget.distribution.total * 100).toStringAsFixed(0)
              : '0';

      return Container(
        key: ValueKey('selected_$touchedIndex'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Star icons row
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(stars, (i) {
                return Icon(Icons.star_rounded, color: color, size: 14.w);
              }),
            ),
            SizedBox(height: 2.h),
            // Count
            Text(
              '$count',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: color,
                height: 1,
              ),
            ),
            // Percentage
            Text(
              '$percentage%',
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    } else {
      // Show total reviews
      return Container(
        key: const ValueKey('total'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${widget.distribution.total}',
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF111726),
                height: 1,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'Reviews'.tr,
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }
  }

  List<PieChartSectionData> _buildSections(RatingDistribution d) {
    final data = _sectionData;

    return data.asMap().entries.map((entry) {
      final index = entry.key;
      final e = entry.value;
      final isTouched = index == touchedIndex;
      final count = e['count'] as int;

      return PieChartSectionData(
        value: count.toDouble(),
        color: e['color'] as Color,
        radius: isTouched ? 32.r : 28.r,
        showTitle: false,
        title: e['label'] as String,
        titleStyle: TextStyle(
          fontSize: isTouched ? 11.sp : 9.sp,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows:
              isTouched
                  ? const [Shadow(color: Colors.black38, blurRadius: 4)]
                  : null,
        ),
        titlePositionPercentageOffset: 0.55,
        borderSide:
            isTouched
                ? const BorderSide(color: Colors.white, width: 2)
                : BorderSide.none,
      );
    }).toList();
  }
}
