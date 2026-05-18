class ChapModel {
  final int id;
  final String ten;
  final String noiDung;

  ChapModel({
    required this.id,
    required this.ten,
    required this.noiDung,
  });

  factory ChapModel.fromJson(Map<String, dynamic> json) {
    return ChapModel(
      id: json['id'] as int? ?? 0,
      ten: json['ten'] as String? ?? 'Chương không tên',
      noiDung: json['noi_dung'] as String? ?? 'Nội dung trống',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ten': ten,
      'noi_dung': noiDung,
    };
  }
}
