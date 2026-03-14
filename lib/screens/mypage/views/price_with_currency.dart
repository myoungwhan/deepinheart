import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:deepinheart/views/ui_helpers.dart';
import 'package:flutter/material.dart';

class PriceWithCurrency extends StatelessWidget {
  String amount;
  bool isLineThroug;
  double fSize;
  PriceWithCurrency({
    Key? key,
    required this.amount,
    this.isLineThroug = false,
    this.fSize = 14.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomText(
          text: "₩",
          weight:
              isLineThroug
                  ? FontWeightConstants.regular
                  : FontWeightConstants.black,
          fontSize: fSize,

          decoration: isLineThroug ? TextDecoration.lineThrough : null,
        ),
        CustomText(
          text: UIHelper.getCurrencyFormate(amount),
          weight:
              isLineThroug
                  ? FontWeightConstants.regular
                  : FontWeightConstants.black,
          fontSize: fSize,
          decoration: isLineThroug ? TextDecoration.lineThrough : null,
        ),
      ],
    );
  }
}
