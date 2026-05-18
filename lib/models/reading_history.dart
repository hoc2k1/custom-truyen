class ReadingHistory {
  final String truyenId;
  final int chapId;
  final double progress; // Phần trăm tiến độ đọc (từ 0.0 đến 1.0)
  final DateTime lastRead;

  ReadingHistory({
    required this.truyenId,
    required this.chapId,
    required this.progress,
    required this.lastRead,
  });

  factory ReadingHistory.fromJson(Map<String, dynamic> json) {
    return ReadingHistory(
      truyenId: json['truyenId'] as String? ?? '',
      chapId: json['chapId'] as int? ?? 1,
      progress: (json['progress'] as num? ?? 0.0).toDouble(),
      lastRead: json['lastRead'] != null 
          ? DateTime.parse(json['lastRead'] as String) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'truyenId': truyenId,
      'chapId': chapId,
      'progress': progress,
      'lastRead': lastRead.toIso8601String(),
    };
  }
}
