import 'package:deepinheart/Controller/Model/consultation_package_model.dart';
import 'package:deepinheart/main.dart';
import 'package:deepinheart/views/colors.dart';
import 'package:flutter/material.dart';

class ConsultationSelectorWithRadio extends StatefulWidget {
  final List<ConsultationPackage> packages;
  final ValueChanged<int>? onChanged;
  const ConsultationSelectorWithRadio({
    Key? key,
    required this.packages,
    this.onChanged,
  }) : super(key: key);
  @override
  _ConsultationSelectorWithRadioState createState() =>
      _ConsultationSelectorWithRadioState();
}

class _ConsultationSelectorWithRadioState
    extends State<ConsultationSelectorWithRadio> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...List.generate(widget.packages.length, (i) {
          final pkg = widget.packages[i];
          return Card(
            color: isMainDark ? Color(0xff2C2C2E) : Colors.white,
            shape: RoundedRectangleBorder(
              side: BorderSide(
                color:
                    _selectedIndex == i ? primaryColor : Colors.grey.shade300,
                width: _selectedIndex == i ? 1 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.only(bottom: 12),
            child: RadioListTile<int>(
              value: i,
              groupValue: _selectedIndex,
              onChanged: (val) {
                setState(() => _selectedIndex = val);
                if (val != null) widget.onChanged?.call(val);
              },
              activeColor: Theme.of(context).primaryColor,
              tileColor:
                  _selectedIndex == i
                      ? isMainDark
                          ? Color(0xff2C2C2E)
                          : Colors.grey.shade50
                      : isMainDark
                      ? Color(0xff2C2C2E)
                      : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.all(12),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      pkg.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${pkg.discountPercent}% OFF',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pkg.subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.monetization_on_outlined,
                          size: 16,
                          color: Colors.amber.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${pkg.originalPrice.toInt()}',
                          style: TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey.shade500,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${pkg.discountedPrice.toInt()}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
