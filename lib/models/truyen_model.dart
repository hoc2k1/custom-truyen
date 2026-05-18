import 'chap_model.dart';

class TruyenModel {
  final String ten;
  final String id;
  final List<ChapModel> chapList;

  TruyenModel({
    required this.ten,
    required this.id,
    required this.chapList,
  });

  factory TruyenModel.fromJson(Map<String, dynamic> json) {
    var list = json['chap'] as List? ?? [];
    List<ChapModel> chaps = list.map((i) => ChapModel.fromJson(i as Map<String, dynamic>)).toList();

    return TruyenModel(
      ten: json['ten'] as String? ?? 'Không có tên',
      id: json['id'] as String? ?? '',
      chapList: chaps,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ten': ten,
      'id': id,
      'chap': chapList.map((c) => c.toJson()).toList(),
    };
  }

  // Lấy ID chương cuối cùng làm tổng số chương theo yêu cầu người dùng
  int get totalChapters => chapList.isNotEmpty ? chapList.last.id : 0;
}
