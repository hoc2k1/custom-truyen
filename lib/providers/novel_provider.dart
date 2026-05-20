import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../models/truyen_model.dart';

class NovelProvider with ChangeNotifier {
  List<TruyenModel> _novels = [];
  bool _isLoading = false;
  String _errorMessage = '';

  List<TruyenModel> get novels => _novels;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  // Load và parse dữ liệu truyện từ local JSON
  Future<void> loadNovels({bool forceReload = false}) async {
    if (_novels.isNotEmpty && !forceReload) return; // Chỉ load một lần duy nhất

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      String response;
      
      // Kiểm tra file custom_data.json trong Document Directory
      final directory = await getApplicationDocumentsDirectory();
      final customFile = File('${directory.path}/custom_data.json');
      
      if (await customFile.exists()) {
        response = await customFile.readAsString();
      } else {
        // Đọc file JSON từ folder assets/data
        response = await rootBundle.loadString('assets/data/output.json');
      }

      final data = json.decode(response);

      if (data != null && data['truyen'] != null) {
        var truyenList = data['truyen'] as List;
        _novels = truyenList
            .map((item) => TruyenModel.fromJson(item as Map<String, dynamic>))
            .toList();
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

  // Import file JSON mới
  Future<void> importCustomData(String filePath) async {
    try {
      final sourceFile = File(filePath);
      if (!await sourceFile.exists()) return;

      final directory = await getApplicationDocumentsDirectory();
      final targetFile = File('${directory.path}/custom_data.json');
      
      // Copy nội dung file được chọn vào file lưu trữ
      await sourceFile.copy(targetFile.path);
      
      // Load lại dữ liệu
      await loadNovels(forceReload: true);
    } catch (e) {
      _errorMessage = 'Lỗi khi import file: $e';
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
