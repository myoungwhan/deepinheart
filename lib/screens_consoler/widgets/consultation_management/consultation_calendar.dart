import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';

class ConsultationCalendar extends StatefulWidget {
  final DateTime? selectedDate;
  final Function(DateTime) onDateSelected;
  final List<DateTime> consultationDates;

  const ConsultationCalendar({
    Key? key,
    this.selectedDate,
    required this.onDateSelected,
    required this.consultationDates,
  }) : super(key: key);

  @override
  _ConsultationCalendarState createState() => _ConsultationCalendarState();
}

class _ConsultationCalendarState extends State<ConsultationCalendar> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = widget.selectedDate ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 4,
            offset: Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          // Calendar header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(
                text: '${_getMonthName(_focusedDay.month)} ${_focusedDay.year}',
                fontSize: FontConstants.font_18,
                weight: FontWeight.w600,
                color: Color(0xFF111726),
              ),
              Row(
                children: [
                  _buildNavigationButton(Icons.chevron_left, () {
                    setState(() {
                      _focusedDay = DateTime(
                        _focusedDay.year,
                        _focusedDay.month - 1,
                      );
                    });
                  }),
                  SizedBox(width: 8.w),
                  _buildNavigationButton(Icons.chevron_right, () {
                    setState(() {
                      _focusedDay = DateTime(
                        _focusedDay.year,
                        _focusedDay.month + 1,
                      );
                    });
                  }),
                ],
              ),
            ],
          ),

          SizedBox(height: 16.h),

          // Calendar
          TableCalendar<DateTime>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            headerVisible: false,

            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              widget.onDateSelected(selectedDay);
            },
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
            },
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              weekendTextStyle: TextStyle(color: Color(0xFF6B7280)),
              defaultTextStyle: TextStyle(color: Color(0xFF111726)),
              selectedDecoration: BoxDecoration(
                color: Color(0xFF3B81F5),
                shape: BoxShape.circle,
              ),
              selectedTextStyle: TextStyle(color: Colors.white),
              todayDecoration: BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: Color(0xFF3B81F5), width: 2),
              ),
              todayTextStyle: TextStyle(color: Color(0xFF3B81F5)),
              markersMaxCount: 1,
              markerDecoration: BoxDecoration(
                color: Color(0xFF3B81F5),
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: false,
              leftChevronVisible: false,
              rightChevronVisible: false,
              titleTextStyle: TextStyle(
                fontSize: FontConstants.font_16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111726),
              ),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(color: Color(0xFF6B7280)),
              weekendStyle: TextStyle(color: Color(0xFF6B7280)),
            ),
            eventLoader: (day) {
              return widget.consultationDates
                  .where((date) => isSameDay(date, day))
                  .toList();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32.w,
        height: 32.h,
        decoration: BoxDecoration(
          color: Color(0xFFF3F4F6),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20.sp, color: Color(0xFF6B7280)),
      ),
    );
  }

  String _getMonthName(int month) {
    final months = [
      'January'.tr,
      'February'.tr,
      'March'.tr,
      'April'.tr,
      'May'.tr,
      'June'.tr,
      'July'.tr,
      'August'.tr,
      'September'.tr,
      'October'.tr,
      'November'.tr,
      'December'.tr,
    ];
    return months[month - 1];
  }
}
