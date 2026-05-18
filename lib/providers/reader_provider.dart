import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reader_settings.dart';
import '../models/reading_history.dart';

class ReaderProvider with ChangeNotifier {
  late SharedPreferences _prefs;
  bool _isInitialized = false;

  // Cấu hình giao diện đọc
  late ReaderSettings _settings;
  String _themeModeString = 'dark'; // 'dark' | 'light' | 'sepia' | 'gray'

  // Lịch sử đọc của tất cả truyện: Map<truyenId, ReadingHistory>
  final Map<String, ReadingHistory> _history = {};

  ReaderProvider() {
    _initPrefs();
  }

  bool get isInitialized => _isInitialized;
  ReaderSettings get settings => _settings;
  String get themeModeString => _themeModeString;

  // Khởi tạo SharedPreferences
  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    
    // 1. Tải cài đặt giao diện
    _themeModeString = _prefs.getString('reader_theme_mode') ?? 'dark';
    double fontSize = _prefs.getDouble('reader_font_size') ?? 18.0;
    double lineHeight = _prefs.getDouble('reader_line_height') ?? 1.6;

    _applyThemeSettings(_themeModeString, fontSize, lineHeight);

    // 2. Tải toàn bộ lịch sử đọc
    final Set<String> keys = _prefs.getKeys();
    for (String key in keys) {
      if (key.startsWith('reading_history_')) {
        final String truyenId = key.replaceFirst('reading_history_', '');
        final String? jsonStr = _prefs.getString(key);
        if (jsonStr != null) {
          try {
            final Map<String, dynamic> data = json.decode(jsonStr) as Map<String, dynamic>;
            _history[truyenId] = ReadingHistory.fromJson(data);
          } catch (_) {
            // Bỏ qua lỗi parse JSON không hợp lệ
          }
        }
      }
    }

    _isInitialized = true;
    notifyListeners();
  }

  // Cập nhật Cỡ Chữ
  Future<void> updateFontSize(double size) async {
    if (size < 12.0 || size > 30.0) return;
    _settings.fontSize = size;
    await _prefs.setDouble('reader_font_size', size);
    notifyListeners();
  }

  // Cập nhật Giãn Dòng
  Future<void> updateLineHeight(double height) async {
    _settings.lineHeight = height;
    await _prefs.setDouble('reader_line_height', height);
    notifyListeners();
  }

  // Thay đổi Chủ Đề (Theme Mode)
  Future<void> changeThemeMode(String mode) async {
    if (!['dark', 'light', 'sepia', 'gray'].contains(mode)) return;
    _themeModeString = mode;
    await _prefs.setString('reader_theme_mode', mode);
    
    _applyThemeSettings(mode, _settings.fontSize, _settings.lineHeight);
    notifyListeners();
  }

  // Áp dụng màu sắc dựa vào chủ đề được chọn
  void _applyThemeSettings(String mode, double fontSize, double lineHeight) {
    ReaderSettings base;
    switch (mode) {
      case 'light':
        base = ReaderSettings.lightDefault();
        break;
      case 'sepia':
        base = ReaderSettings.sepiaDefault();
        break;
      case 'gray':
        base = ReaderSettings.grayDefault();
        break;
      case 'dark':
      default:
        base = ReaderSettings.darkDefault();
        break;
    }
    
    _settings = ReaderSettings(
      fontSize: fontSize,
      lineHeight: lineHeight,
      backgroundColor: base.backgroundColor,
      textColor: base.textColor,
    );
  }

  // Lấy lịch sử đọc của một truyện
  ReadingHistory? getHistory(String truyenId) {
    return _history[truyenId];
  }

  // Cập nhật lịch sử đọc truyện
  Future<void> updateHistory(String truyenId, int chapId, double progress) async {
    final historyItem = ReadingHistory(
      truyenId: truyenId,
      chapId: chapId,
      progress: progress,
      lastRead: DateTime.now(),
    );

    _history[truyenId] = historyItem;
    
    // Lưu cục bộ
    final String key = 'reading_history_$truyenId';
    final String jsonStr = json.encode(historyItem.toJson());
    await _prefs.setString(key, jsonStr);
    
    notifyListeners();
  }

  // Xóa lịch sử đọc (nếu cần thiết)
  Future<void> clearHistory(String truyenId) async {
    _history.remove(truyenId);
    await _prefs.remove('reading_history_$truyenId');
    notifyListeners();
  }
}
