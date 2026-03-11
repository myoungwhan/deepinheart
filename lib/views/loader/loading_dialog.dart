import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:deepinheart/Controller/Viewmodel/loading_provider.dart';
import 'package:deepinheart/views/colors.dart';

import 'logo_animated_loading.dart';

class LoadingDialog extends StatelessWidget {
  const LoadingDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<LoadingProvider>().isLoading;
    final feedback = context.watch<LoadingProvider>().feedback;

    if (!isLoading) return const SizedBox.shrink();

    return BackdropFilter(
      filter: ImageFilter.blur(
        sigmaY: 3,
        sigmaX: 3,
      ),
      child: Dialog(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            LogoAnimatedLoading(
              color: primaryColor,
            ),
            if (feedback != null) const SizedBox(height: 4),
            if (feedback != null)
              Text(
                feedback,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }
}
