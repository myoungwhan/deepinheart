import 'package:deepinheart/Controller/Model/filter_model.dart';
import 'package:deepinheart/Controller/Model/reservation_model.dart';
import 'package:deepinheart/config/string_constants.dart';
import 'package:deepinheart/screens/mypage/views/custom_chip_selection.dart';
import 'package:deepinheart/screens/mypage/views/custom_filter_sheet.dart';
import 'package:deepinheart/screens/mypage/views/session_tile.dart';
import 'package:deepinheart/views/custom_appbar.dart';
import 'package:deepinheart/views/custom_textfiled.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/ui_helpers.dart';

class ConsultationHistoryPage extends StatefulWidget {
  final List<Appointment> recentAppointments;

  ConsultationHistoryPage({Key? key, required this.recentAppointments})
    : super(key: key);
  @override
  _ConsultationHistoryPageState createState() =>
      _ConsultationHistoryPageState();
}

class _ConsultationHistoryPageState extends State<ConsultationHistoryPage> {
  late List<Appointment> _all;

  // UI state
  String _search = '';
  String _selectedChip = 'All';
  late List<String> _chips;

  // Filter state
  FilterConfig? _filterConfig;

  @override
  void initState() {
    super.initState();
    _all = widget.recentAppointments;
    _initializeChips();
    _initializeFilter();
  }

  /// Initialize filter with unique counselor names
  void _initializeFilter() {
    final uniqueCounselors = <String>{};
    for (var appointment in _all) {
      uniqueCounselors.add(appointment.counselor.name);
    }

    _filterConfig = FilterConfig(
      types:
          uniqueCounselors
              .map((name) => FilterOption(key: name, selected: true))
              .toList(),
      period: 'All Time',
      sortOrder: 'Latest',
    );
  }

  /// Initialize chips dynamically based on available categories in appointments
  void _initializeChips() {
    // Get unique categories from appointments
    final Set<String> uniqueCategories = {};
    for (var appointment in _all) {
      if (appointment.category.isNotEmpty) {
        uniqueCategories.add(appointment.category);
      }
    }

    // Create chips list: 'All' + unique categories sorted alphabetically
    _chips = ['All', ...uniqueCategories.toList()..sort()];
  }

  /// Check if any filters are currently applied
  bool _hasActiveFilters() {
    if (_filterConfig == null) return false;

    // Check if not all counselors are selected
    final allSelected = _filterConfig!.types.every((t) => t.selected);
    if (!allSelected) return true;

    // Check if period is not "All Time"
    if (_filterConfig!.period != 'All Time') return true;

    // Check if sort order is not "Latest" (default)
    if (_filterConfig!.sortOrder != 'Latest') return true;

    return false;
  }

  /// Clear all filters and reset to default
  void _clearFilters() {
    setState(() {
      _initializeFilter();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Filter appointments based on search and selected chip
    final filteredAppointments = _getFilteredAppointments();

    // Group by date
    final groupedByDate = _groupAppointmentsByDate(filteredAppointments);

    return Scaffold(
      appBar: customAppBar(
        title: 'Consultation History'.tr,
        isLogo: false,
        centerTitle: false,
        action: [
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.filter_list),
                onPressed: () {
                  if (_filterConfig == null) {
                    _initializeFilter();
                  }
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder:
                        (_) => CustomFilterSheet(
                          config: _filterConfig!,
                          onApply: (newConfig) {
                            setState(() {
                              _filterConfig = newConfig;
                            });
                          },
                          onClear: _hasActiveFilters() ? _clearFilters : null,
                        ),
                  );
                },
              ),
              if (_hasActiveFilters())
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8.w,
                    height: 8.w,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),

      body: Column(
        children: [
          // search
          UIHelper.verticalSpaceMd,
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Customtextfield(
              required: false,
              prefix: Icon(Icons.search),
              border: 5.0,
              hint: 'Search counselor or content'.tr,
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          UIHelper.verticalSpaceMd,

          // chips
          CustomSelectionChip(
            chips: _chips,
            selectedChip: _selectedChip,
            onSelected: (value) {
              setState(() {
                _selectedChip = value;
              });
            },
          ),
          UIHelper.verticalSpaceSm,

          // list
          Expanded(child: _buildAppointmentsList(groupedByDate)),
        ],
      ),
    );
  }

  /// Filter appointments based on search query, selected chip, and filter config
  List<Appointment> _getFilteredAppointments() {
    var filtered =
        _all.where((appointment) {
          // Search filter: check counselor name and consultation content
          if (_search.isNotEmpty) {
            final searchLower = _search.toLowerCase();
            final nameMatch = appointment.counselor.name.toLowerCase().contains(
              searchLower,
            );
            final contentMatch =
                appointment.consultationContent?.toLowerCase().contains(
                  searchLower,
                ) ??
                false;

            if (!nameMatch && !contentMatch) {
              return false;
            }
          }

          // Category chip filter
          if (_selectedChip != 'All') {
            final appointmentCategory = appointment.category.toLowerCase();
            final selectedCategory = _selectedChip.toLowerCase();

            if (appointmentCategory != selectedCategory) {
              return false;
            }
          }

          // Filter by selected counselor names
          if (_filterConfig != null) {
            final selectedCounselors =
                _filterConfig!.types
                    .where((t) => t.selected)
                    .map((t) => t.key)
                    .toList();

            if (selectedCounselors.isNotEmpty &&
                !selectedCounselors.contains(appointment.counselor.name)) {
              return false;
            }
          }

          // Period filter
          if (_filterConfig != null && _filterConfig!.period != 'All Time') {
            DateTime appointmentDate;
            try {
              if (appointment.date != null && appointment.date!.isNotEmpty) {
                appointmentDate = DateTime.parse(appointment.date!);
              } else {
                return true; // Include if date is invalid
              }
            } catch (_) {
              return true; // Include if date parsing fails
            }

            final now = DateTime.now();
            DateTime? startDate;
            DateTime endDate = now;

            switch (_filterConfig!.period) {
              case 'Last 1 Month':
                startDate = DateTime(now.year, now.month - 1, now.day);
                break;
              case 'Last 3 Months':
                startDate = DateTime(now.year, now.month - 3, now.day);
                break;
              case 'Last 6 Months':
                startDate = DateTime(now.year, now.month - 6, now.day);
                break;
              case 'Custom':
                startDate = _filterConfig!.startDate;
                endDate = _filterConfig!.endDate ?? now;
                break;
            }

            if (startDate != null) {
              if (appointmentDate.isBefore(startDate) ||
                  appointmentDate.isAfter(endDate)) {
                return false;
              }
            }
          }

          return true;
        }).toList();

    // Apply sort order
    if (_filterConfig != null) {
      filtered = filtered.toList();
      filtered.sort((a, b) {
        DateTime dateA;
        DateTime dateB;

        try {
          dateA =
              a.date != null && a.date!.isNotEmpty
                  ? DateTime.parse(a.date!)
                  : DateTime(1970);
          dateB =
              b.date != null && b.date!.isNotEmpty
                  ? DateTime.parse(b.date!)
                  : DateTime(1970);
        } catch (_) {
          return 0;
        }

        if (_filterConfig!.sortOrder == 'Latest') {
          return dateB.compareTo(dateA); // Newest first
        } else {
          return dateA.compareTo(dateB); // Oldest first
        }
      });
    }

    return filtered;
  }

  /// Group appointments by date
  Map<String, List<Appointment>> _groupAppointmentsByDate(
    List<Appointment> appointments,
  ) {
    final Map<String, List<Appointment>> grouped = {};

    for (var appointment in appointments) {
      DateTime dateTime;
      try {
        if (appointment.date != null && appointment.date!.isNotEmpty) {
          dateTime = DateTime.parse(appointment.date!);
        } else {
          dateTime = DateTime.now();
        }
      } catch (_) {
        dateTime = DateTime.now();
      }

      String header = DateFormat('yyyy년 M월 d일 (E)')
          .format(dateTime)
          .replaceAll('Wed', '수')
          .replaceAll('Sat', '토')
          .replaceAll('Sun', '일')
          .replaceAll('Mon', '월')
          .replaceAll('Tue', '화')
          .replaceAll('Thu', '목')
          .replaceAll('Fri', '금');

      grouped.putIfAbsent(header, () => []).add(appointment);
    }

    // Sort by date based on filter config
    final sortOrder = _filterConfig?.sortOrder ?? 'Latest';
    final sortedEntries =
        grouped.entries.toList()..sort((a, b) {
          try {
            final dateA = DateFormat('yyyy년 M월 d일 (E)').parse(a.key);
            final dateB = DateFormat('yyyy년 M월 d일 (E)').parse(b.key);
            if (sortOrder == 'Latest') {
              return dateB.compareTo(dateA); // Descending order (newest first)
            } else {
              return dateA.compareTo(dateB); // Ascending order (oldest first)
            }
          } catch (_) {
            return 0;
          }
        });

    return Map.fromEntries(sortedEntries);
  }

  /// Build the appointments list widget
  Widget _buildAppointmentsList(Map<String, List<Appointment>> groupedByDate) {
    if (groupedByDate.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64.w,
              color: Colors.grey[300],
            ),
            SizedBox(height: 16.h),
            CustomText(
              text:
                  _search.isNotEmpty || _selectedChip != 'All'
                      ? 'No conversations found'.tr
                      : 'No conversations yet'.tr,
              fontSize: FontConstants.font_16,
              weight: FontWeightConstants.medium,
              color: Colors.grey[500],
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.symmetric(vertical: 8),
      children:
          groupedByDate.entries.map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date header
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      CustomText(
                        text: entry.key,
                        fontSize: 14,
                        weight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                      UIHelper.horizontalSpaceSm,
                      CustomText(
                        text: '${entry.value.length}건',
                        fontSize: 12,
                        weight: FontWeight.w400,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
                // Appointment items
                ...entry.value.map((appointment) {
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: SessionTile(
                      method: appointment.methodText.tr,
                      imageUrl:
                          appointment.counselor.image.isNotEmpty
                              ? appointment.counselor.image
                              : testuserprofile,
                      name: appointment.counselor.name,
                      category:
                          (appointment.category.isNotEmpty
                                  ? appointment.category
                                  : appointment.methodText)
                              .tr,
                      date: appointment.date ?? '',
                      duration: '${appointment.reservedCoins} ' + 'Coins'.tr,
                      description: appointment.consultationContent ?? ''.tr,
                    ),
                  );
                }).toList(),
              ],
            );
          }).toList(),
    );
  }
}
