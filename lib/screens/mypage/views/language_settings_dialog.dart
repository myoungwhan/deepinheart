import 'package:deepinheart/Controller/Viewmodel/userviewmodel.dart';
import 'package:deepinheart/Controller/locale_controller.dart';
import 'package:deepinheart/views/colors.dart';
import 'package:deepinheart/views/custom_button.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageDialog extends StatefulWidget {
  @override
  _LanguageDialogState createState() => _LanguageDialogState();
}

class _LanguageDialogState extends State<LanguageDialog> {
  // Pull in your langs/locales from the service
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    // Initialize with the current locale
    _selectedIndex = LocalizationService.locales.indexWhere(
      (loc) =>
          loc.languageCode == Get.locale?.languageCode &&
          loc.countryCode == Get.locale?.countryCode,
    );
    if (_selectedIndex == -1) _selectedIndex = 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDarkMode ? theme.dialogBackgroundColor : Colors.white,
      insetPadding: EdgeInsets.symmetric(horizontal: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        'Language setting'.tr,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 18,
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      content: SizedBox(
        width: Get.width * 0.8,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Column(
                children: List.generate(LocalizationService.langs.length, (i) {
                  final isSelected = _selectedIndex == i;
                  return Container(
                    margin: EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? primaryColor.withOpacity(0.15)
                              : (isDarkMode
                                  ? Colors.white10
                                  : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            isSelected
                                ? primaryColor
                                : (isDarkMode
                                    ? Colors.white24
                                    : Colors.grey.shade300),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: RadioListTile<int>(
                      value: i,
                      groupValue: _selectedIndex,
                      onChanged: (val) {
                        setState(() => _selectedIndex = val!);
                      },
                      title: CustomText(
                        text: LocalizationService.langs[i],
                        fontSize: 16,
                        weight: FontWeight.w500,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      activeColor: primaryColor,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      tileColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                }),
              ),
              UIHelper.verticalSpaceMd,
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      () {
                        Get.back();
                      },
                      text: 'Cancel'.tr,
                      isCancelButton: true,
                    ),
                  ),

                  SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(() async {
                      final selectedLocale =
                          LocalizationService.locales[_selectedIndex];

                      // Save language preference to SharedPreferences
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString(
                        'saved_language_code',
                        selectedLocale.languageCode,
                      );
                      await prefs.setString(
                        'saved_country_code',
                        selectedLocale.countryCode ?? '',
                      );

                      Get.updateLocale(selectedLocale);
                      LocalizationService().changeLocale(
                        selectedLocale.languageCode,
                      );
                      context.read<UserViewModel>().fetchtaxonomie();
                      Get.back();
                    }, text: 'save'.tr),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
