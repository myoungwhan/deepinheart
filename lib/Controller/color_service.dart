import 'package:flutter/material.dart';

class ColorService {
  // Pre-shuffled dark colors from various color families
  static final List<Color> _shuffledColors = [
    Color(0xFFB71C1C), // Dark Red
    Color(0xFF1B5E20), // Dark Green
    Color(0xFF0D47A1), // Dark Blue
    Color(0xFF4A148C), // Dark Purple
    Color(0xFFE65100), // Dark Orange
    Color(0xFF006064), // Dark Teal
    Color(0xFF880E4F), // Dark Pink
    Color(0xFF1565C0), // Blue
    Color(0xFF2E7D32), // Green
    Color(0xFF6A1B9A), // Purple
    Color(0xFFC62828), // Red
    Color(0xFF00695C), // Teal
    Color(0xFF5D4037), // Brown
    Color(0xFF01579B), // Dark Blue
    Color(0xFFAD1457), // Pink
    Color(0xFF33691E), // Light Green Dark
    Color(0xFFF57C00), // Orange
    Color(0xFF4E342E), // Dark Brown
    Color(0xFF283593), // Indigo
    Color(0xFF00838F), // Cyan
    Color(0xFFC41C00), // Bright Red Dark
    Color(0xFF004D40), // Dark Teal
    Color(0xFF512DA8), // Deep Purple
    Color(0xFF827717), // Lime Dark
    Color(0xFFD84315), // Deep Orange
    Color(0xFF311B92), // Deep Purple Dark
    Color(0xFF1A237E), // Indigo Dark
    Color(0xFF558B2F), // Light Green
    Color(0xFFEF6C00), // Orange Dark
    Color(0xFF6A1B9A), // Purple
    Color(0xFF00796B), // Teal
    Color(0xFFD32F2F), // Red
    Color(0xFF7B1FA2), // Purple
    Color(0xFF388E3C), // Green
    Color(0xFF1976D2), // Blue
    Color(0xFF689F38), // Light Green
    Color(0xFFF57F17), // Yellow Dark
    Color(0xFFE64A19), // Deep Orange
    Color(0xFF455A64), // Blue Grey Dark
    Color(0xFF7CB342), // Light Green
    Color(0xFFFF6F00), // Amber Dark
    Color(0xFF8E24AA), // Purple
    Color(0xFF00897B), // Teal
    Color(0xFF5E35B1), // Deep Purple
    Color(0xFF43A047), // Green
    Color(0xFFFB8C00), // Orange
    Color(0xFF3949AB), // Indigo
    Color(0xFFE53935), // Red
    Color(0xFF00ACC1), // Cyan
    Color(0xFF8D6E63), // Brown
  ];

  /// Get color by index (with wrap-around)
  static Color getColor(int index) {
    if (_shuffledColors.isEmpty) return Colors.black;
    return _shuffledColors[index % _shuffledColors.length];
  }
}
