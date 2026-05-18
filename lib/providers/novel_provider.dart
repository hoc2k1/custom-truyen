import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/truyen_model.dart';

class NovelProvider with ChangeNotifier {
  List<TruyenModel> _novels = [];
  bool _isLoading = false;
  String _errorMessage = '';

  List<TruyenModel> get novels => _novels;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  // Load và parse dữ liệu truyện từ local JSON
  Future<void> loadNovels() async {
    if (_novels.isNotEmpty) return; // Chỉ load một lần duy nhất
    
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      // Đọc file JSON từ folder assests/data
      final String response = await rootBundle.loadString('assests/data/output.json');
      final data = json.decode(response);
      
      if (data != null && data['truyen'] != null) {
        var truyenList = data['truyen'] as List;
        _novels = truyenList.map((item) => TruyenModel.fromJson(item as Map<String, dynamic>)).toList();
      } else {
        _errorMessage = 'Dữ liệu không đúng cấu trúc';
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error loading novels: $e\n$stackTrace');
      }
      _errorMessage = 'Không thể tải dữ liệu truyện: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Lấy chi tiết truyện bằng ID truyện
  TruyenModel? getNovelById(String id) {
    try {
      return _novels.firstWhere((n) => n.id == id);
    } catch (_) {
      return null;
    }
  }
}
