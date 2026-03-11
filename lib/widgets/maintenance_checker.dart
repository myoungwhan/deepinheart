import 'package:deepinheart/Controller/Viewmodel/setting_provider.dart';
import 'package:deepinheart/widgets/maintenance_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Widget that automatically checks and shows maintenance dialog when settings are loaded
class MaintenanceChecker extends StatefulWidget {
  final Widget child;

  const MaintenanceChecker({Key? key, required this.child}) : super(key: key);

  @override
  State<MaintenanceChecker> createState() => _MaintenanceCheckerState();
}

class _MaintenanceCheckerState extends State<MaintenanceChecker> {
  bool _hasShownDialog = false;

  @override
  void initState() {
    super.initState();
    // Wait a bit for the context to be ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkMaintenance();
    });
  }

  void _checkMaintenance() {
    if (_hasShownDialog) return;

    final settingProvider = Provider.of<SettingProvider>(
      context,
      listen: false,
    );

    debugPrint('🔍 MaintenanceChecker: Initial check');
    debugPrint('   - isLoading: ${settingProvider.isLoading}');
    debugPrint('   - hasSettings: ${settingProvider.hasSettings}');

    // Wait for settings to be loaded
    if (settingProvider.isLoading) {
      debugPrint(
        '⏳ MaintenanceChecker: Settings still loading, adding listener...',
      );
      // Listen for when settings finish loading
      settingProvider.addListener(_onSettingsChanged);
      return;
    }

    // Settings already loaded, check with a delay to ensure context is ready
    if (settingProvider.hasSettings) {
      debugPrint('✅ MaintenanceChecker: Settings already loaded, checking...');
      Future.delayed(Duration(milliseconds: 800), () {
        if (mounted && !_hasShownDialog) {
          _showDialogIfNeeded();
        }
      });
    } else {
      debugPrint(
        '⚠️ MaintenanceChecker: Settings not loaded, adding listener...',
      );
      settingProvider.addListener(_onSettingsChanged);
    }
  }

  void _onSettingsChanged() {
    final settingProvider = Provider.of<SettingProvider>(
      context,
      listen: false,
    );

    // Check if settings are now loaded
    if (!settingProvider.isLoading && !_hasShownDialog) {
      debugPrint(
        '📥 MaintenanceChecker: Settings loaded, checking maintenance...',
      );
      // Remove listener to avoid multiple calls
      settingProvider.removeListener(_onSettingsChanged);
      // Add a delay to ensure UI is ready
      Future.delayed(Duration(milliseconds: 800), () {
        if (mounted && !_hasShownDialog) {
          _showDialogIfNeeded();
        }
      });
    }
  }

  void _showDialogIfNeeded() {
    if (_hasShownDialog) return;

    final settingProvider = Provider.of<SettingProvider>(
      context,
      listen: false,
    );

    // Ensure settings are loaded
    if (!settingProvider.hasSettings) {
      debugPrint('⚠️ MaintenanceChecker: Settings not loaded yet');
      return;
    }

    debugPrint('🔍 MaintenanceChecker: Checking maintenance status...');
    debugPrint(
      '   - showMaintenanceMode: ${settingProvider.isInMaintenanceMode}',
    );
    debugPrint(
      '   - completeServiceShutdown: ${settingProvider.isServiceShutdown}',
    );
    debugPrint(
      '   - maintenanceMessage: ${settingProvider.maintenanceMessage}',
    );
    debugPrint(
      '   - serviceShutdownMessage: ${settingProvider.serviceShutdownMessage}',
    );

    // Check service shutdown first (higher priority)
    // Directly check completeServiceShutdown field
    final completeServiceShutdown =
        settingProvider.settings?.completeServiceShutdown ?? false;

    if (completeServiceShutdown) {
      final shutdownMessage = settingProvider.serviceShutdownMessage;
      if (shutdownMessage.isNotEmpty) {
        debugPrint(
          '🚨 MaintenanceChecker: completeServiceShutdown is TRUE - Showing service shutdown dialog',
        );
        _hasShownDialog = true;
        // Use a delay to ensure context and navigator are ready
        // Wait longer to ensure Navigator is fully initialized
        Future.delayed(Duration(milliseconds: 2000), () {
          if (!mounted) return;
          _showDialogSafely(shutdownMessage, isServiceShutdown: true);
        });
        return;
      }
    } else {
      debugPrint('ℹ️ MaintenanceChecker: completeServiceShutdown is FALSE');
    }

    // Check maintenance mode - ONLY show if show_maintenance_mode is true
    // Directly check the showMaintenanceMode field to ensure it's true
    final showMaintenanceMode =
        settingProvider.settings?.showMaintenanceMode ?? false;

    debugPrint('🔧 MaintenanceChecker: Checking show_maintenance_mode');
    debugPrint('   - showMaintenanceMode (direct): $showMaintenanceMode');
    debugPrint(
      '   - isInMaintenanceMode (getter): ${settingProvider.isInMaintenanceMode}',
    );

    if (showMaintenanceMode) {
      final maintenanceMessage = settingProvider.maintenanceMessage;
      final startTime = settingProvider.maintenanceStartTime;
      final endTime = settingProvider.maintenanceEndTime;

      debugPrint('🔧 MaintenanceChecker: show_maintenance_mode is TRUE');
      debugPrint('   - Message: $maintenanceMessage');
      debugPrint('   - Start Time: $startTime');
      debugPrint('   - End Time: $endTime');

      // Show dialog only if message is not empty
      if (maintenanceMessage.isNotEmpty) {
        debugPrint('✅ MaintenanceChecker: Showing maintenance dialog');
        _hasShownDialog = true;
        // Use a delay to ensure context and navigator are ready
        // Wait longer to ensure Navigator is fully initialized
        Future.delayed(Duration(milliseconds: 2000), () {
          if (!mounted) return;
          _showDialogSafely(
            maintenanceMessage,
            startTime: startTime.isNotEmpty ? startTime : null,
            endTime: endTime.isNotEmpty ? endTime : null,
          );
        });
      } else {
        debugPrint(
          '⚠️ MaintenanceChecker: show_maintenance_mode is true but message is empty',
        );
      }
    } else {
      debugPrint(
        'ℹ️ MaintenanceChecker: show_maintenance_mode is FALSE - dialog will not show',
      );
    }
  }

  void _showDialogSafely(
    String message, {
    bool isServiceShutdown = false,
    String? startTime,
    String? endTime,
  }) {
    if (!mounted) return;

    // Helper function to attempt showing dialog
    void attemptShowDialog() {
      if (!mounted) return;

      // Check if Navigator is available
      final navigator = Navigator.maybeOf(context, rootNavigator: true);
      if (navigator == null) {
        return; // Navigator not ready
      }

      try {
        debugPrint('✅ MaintenanceChecker: Showing dialog');
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => MaintenanceDialog(
                isServiceShutdown: isServiceShutdown,
                message: message,
                startTime: startTime,
                endTime: endTime,
              ),
        );
      } catch (e) {
        debugPrint('❌ MaintenanceChecker: Error showing dialog: $e');
      }
    }

    // Wait for multiple frames to ensure Navigator is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Wait another frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        // Try to show immediately
        final navigator = Navigator.maybeOf(context, rootNavigator: true);
        if (navigator != null) {
          attemptShowDialog();
        } else {
          debugPrint(
            '⚠️ MaintenanceChecker: Navigator not ready, will retry...',
          );

          // Retry with increasing delays
          Future.delayed(Duration(milliseconds: 1000), () {
            if (!mounted) return;
            attemptShowDialog();
          });

          Future.delayed(Duration(milliseconds: 2500), () {
            if (!mounted) return;
            final retryNavigator = Navigator.maybeOf(
              context,
              rootNavigator: true,
            );
            if (retryNavigator != null) {
              attemptShowDialog();
            } else {
              debugPrint(
                '⚠️ MaintenanceChecker: Still waiting for Navigator...',
              );
            }
          });

          Future.delayed(Duration(milliseconds: 5000), () {
            if (!mounted) return;
            final finalNavigator = Navigator.maybeOf(
              context,
              rootNavigator: true,
            );
            if (finalNavigator != null) {
              attemptShowDialog();
            } else {
              debugPrint(
                '❌ MaintenanceChecker: Navigator unavailable after 5 seconds',
              );
            }
          });
        }
      });
    });
  }

  @override
  void dispose() {
    final settingProvider = Provider.of<SettingProvider>(
      context,
      listen: false,
    );
    settingProvider.removeListener(_onSettingsChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use Consumer to listen to SettingProvider changes
    return Consumer<SettingProvider>(
      builder: (context, settingProvider, child) {
        // Check maintenance when settings change
        if (settingProvider.hasSettings &&
            !_hasShownDialog &&
            !settingProvider.isLoading) {
          // Wait for multiple frames to ensure Navigator is ready
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Wait another frame
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_hasShownDialog) {
                // Add a small delay to ensure Navigator is fully initialized
                Future.delayed(Duration(milliseconds: 100), () {
                  if (mounted && !_hasShownDialog) {
                    _showDialogIfNeeded();
                  }
                });
              }
            });
          });
        }
        return widget.child;
      },
    );
  }
}
