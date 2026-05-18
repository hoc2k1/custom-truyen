import 'package:flutter/material.dart';

class ReaderSettings {
  double fontSize;
  double lineHeight;
  Color backgroundColor;
  Color textColor;

  ReaderSettings({
    required this.fontSize,
    required this.lineHeight,
    required this.backgroundColor,
    required this.textColor,
  });

  // Mặc định chủ đề tối Obsidian
  factory ReaderSettings.darkDefault() {
    return ReaderSettings(
      fontSize: 18.0,
      lineHeight: 1.6,
      backgroundColor: const Color(0xFF121212),
      textColor: const Color(0xFFE0E0E0),
    );
  }

  // Chủ đề sáng
  factory ReaderSettings.lightDefault() {
    return ReaderSettings(
      fontSize: 18.0,
      lineHeight: 1.6,
      backgroundColor: const Color(0xFFF9F9F9),
      textColor: const Color(0xFF1E1E1E),
    );
  }

  // Chủ đề vàng giấy cổ (Sepia)
  factory ReaderSettings.sepiaDefault() {
    return ReaderSettings(
      fontSize: 18.0,
      lineHeight: 1.6,
      backgroundColor: const Color(0xFFF4ECD8),
      textColor: const Color(0xFF3C2F2F),
    );
  }

  // Chủ đề xám dịu
  factory ReaderSettings.grayDefault() {
    return ReaderSettings(
      fontSize: 18.0,
      lineHeight: 1.6,
      backgroundColor: const Color(0xFF2D2D2D),
      textColor: const Color(0xFFCCCCCC),
    );
  }
}
