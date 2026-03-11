import 'package:deepinheart/Controller/Model/filter_model.dart';
import 'package:deepinheart/views/colors.dart';
import 'package:deepinheart/views/custom_button.dart';
import 'package:deepinheart/views/ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:get/get.dart';

class CustomFilterSheet extends StatefulWidget {
  final FilterConfig config;
  final Function(FilterConfig) onApply;
  final VoidCallback? onClear;

  const CustomFilterSheet({
    Key? key,
    required this.config,
    required this.onApply,
    this.onClear,
  }) : super(key: key);

  @override
  _CustomFilterSheetState createState() => _CustomFilterSheetState();
}

class _CustomFilterSheetState extends State<CustomFilterSheet> {
  late FilterConfig _current;

  @override
  void initState() {
    super.initState();
    _current = widget.config; // work on a copy
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(
              text: "Consultation Filter".tr,
              fontSize: 18,
              weight: FontWeight.w600,
              color: Colors.black,
            ),

            const SizedBox(height: 16),
            CustomText(
              text: "Consultation Type".tr,
              fontSize: 16,
              weight: FontWeight.w500,
              color: Colors.black,
            ),

            Wrap(
              spacing: 8,
              children:
                  _current.types.map((t) {
                    return FilterChip(
                      label: CustomText(
                        text: t.key,
                        fontSize: 14,
                        weight: FontWeight.w400,
                        color: t.selected ? Colors.white : Colors.black,
                      ),
                      selected: t.selected,
                      onSelected: (v) => setState(() => t.selected = v),
                      selectedColor: primaryColor,
                      backgroundColor: Colors.grey[200],
                      checkmarkColor: whiteColor,
                    );
                  }).toList(),
            ),

            const SizedBox(height: 24),
            CustomText(
              text: "Consultation Period".tr,
              fontSize: 16,
              weight: FontWeight.w500,
              color: Colors.black,
            ),
            UIHelper.verticalSpaceSm,
            Builder(
              builder: (context) {
                final periodOptions = [
                  "All Time",
                  "Last 1 Month",
                  "Last 3 Months",
                  "Last 6 Months",
                  "Custom",
                ];
                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // 2 items per row
                    crossAxisSpacing: 5, // Spacing between items
                    mainAxisSpacing: 5, // Spacing between rows
                    childAspectRatio: 3.5,
                  ),
                  itemCount: periodOptions.length,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemBuilder: (BuildContext context, int index) {
                    final opt = periodOptions[index];
                    return RadioListTile<String>(
                      value: opt,
                      contentPadding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(width: 0.3),
                      ),
                      groupValue: _current.period,
                      onChanged: (v) => setState(() => _current.period = v!),
                      title: CustomText(
                        text: opt.tr,
                        fontSize: 14,
                        weight: FontWeight.w400,
                        color: Colors.black,
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 24),
            CustomText(
              text: "Sort Order".tr,
              fontSize: 16,
              weight: FontWeight.w500,
              color: Colors.black,
            ),
            UIHelper.verticalSpaceSm,

            Builder(
              builder: (context) {
                final sortOptions = ["Latest", "Oldest"];
                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // 2 items per row
                    crossAxisSpacing: 5, // Spacing between items
                    mainAxisSpacing: 5, // Spacing between rows
                    childAspectRatio: 3.5,
                  ),
                  itemCount: sortOptions.length,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemBuilder: (BuildContext context, int index) {
                    final opt = sortOptions[index];
                    return RadioListTile<String>(
                      value: opt,
                      contentPadding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(width: 0.3),
                      ),
                      groupValue: _current.sortOrder,
                      onChanged: (v) => setState(() => _current.sortOrder = v!),
                      title: CustomText(
                        text: opt.tr,
                        fontSize: 14,
                        weight: FontWeight.w400,
                        color: Colors.black,
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 24),
            if (widget.onClear != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      widget.onClear?.call();
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colors.grey[400]!),
                    ),
                    child: CustomText(
                      text: "Clear Filters".tr,
                      fontSize: 14,
                      weight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    () {
                      Get.back();
                    },
                    text: "Cancel".tr,
                    isCancelButton: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(() {
                    widget.onApply(_current);
                    Navigator.pop(context);
                  }, text: "Apply".tr),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
