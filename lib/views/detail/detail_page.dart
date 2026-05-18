import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/truyen_model.dart';
import '../../providers/reader_provider.dart';
import '../../utils/constants.dart';
import '../reader/reader_page.dart';

class DetailPage extends StatefulWidget {
  final TruyenModel novel;

  const DetailPage({super.key, required this.novel});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  int _currentPageIndex = 0; // Trang hiện tại trong danh sách phân trang (0 = chương 1-100)
  final int _chaptersPerPage = 100;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundDark,
      body: Consumer<ReaderProvider>(
        builder: (context, readerProv, child) {
          final history = readerProv.getHistory(widget.novel.id);
          final totalChapters = widget.novel.chapList.length;
          final totalChaptersId = widget.novel.totalChapters;
          
          // Phân trang
          final int totalPages = (totalChapters / _chaptersPerPage).ceil();

          return CustomScrollView(
            slivers: [
              // 1. SliverAppBar với hiệu ứng Glassmorphism & Zoom Header
              SliverAppBar(
                expandedHeight: 320,
                pinned: true,
                backgroundColor: AppConstants.backgroundDark,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Ảnh logo mờ làm nền dạng Glassmorphism
                      Image.asset(
                        AppConstants.logoPath,
                        fit: BoxFit.cover,
                      ),
                      BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          color: Colors.black.withOpacity(0.55),
                        ),
                      ),
                      // Nội dung Header chính
                      Padding(
                        padding: const EdgeInsets.only(top: 80, left: 20, right: 20, bottom: 20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Ảnh bìa truyện chính sắc nét
                            Container(
                              width: 110,
                              height: 150,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                image: const DecorationImage(
                                  image: AssetImage(AppConstants.logoPath),
                                  fit: BoxFit.cover,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.5),
                                    blurRadius: 10,
                                    offset: const Offset(4, 4),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            // Thông tin tên truyện & chương
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.novel.ten,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black,
                                          blurRadius: 10,
                                          offset: Offset(2, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Tổng số chương: $totalChaptersId',
                                    style: TextStyle(
                                      color: Colors.grey[300],
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    history != null
                                        ? 'Đang đọc đến: Chương ${history.chapId} / $totalChaptersId'
                                        : 'Chưa bắt đầu đọc',
                                    style: const TextStyle(
                                      color: AppConstants.accentColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Các nút Action (Đọc tiếp / Đọc từ đầu)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      // Nút Đọc từ đầu
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppConstants.primaryColor, width: 2),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.play_circle_outline_rounded, color: AppConstants.primaryColor),
                          label: const Text(
                            'Đọc Từ Đầu',
                            style: TextStyle(
                              color: AppConstants.primaryColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: () {
                            if (widget.novel.chapList.isNotEmpty) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ReaderPage(
                                    novel: widget.novel,
                                    initialChapterIndex: 0,
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      // Hiển thị nút "Đọc Tiếp" nếu có lịch sử đọc
                      if (history != null) ...[
                        const SizedBox(width: 15),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConstants.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.menu_book_rounded),
                            label: const Text(
                              'Đọc Tiếp',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: () {
                              // Tìm index của chương trong danh sách
                              int savedIndex = widget.novel.chapList.indexWhere(
                                (c) => c.id == history.chapId,
                              );
                              if (savedIndex == -1) savedIndex = 0;

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ReaderPage(
                                    novel: widget.novel,
                                    initialChapterIndex: savedIndex,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // 3. Phân trang Danh sách chương (100 chương 1 trang)
              if (totalPages > 1)
                SliverToBoxAdapter(
                  child: Container(
                    height: 50,
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: totalPages,
                      itemBuilder: (context, index) {
                        int startChap = index * _chaptersPerPage + 1;
                        int endChap = ((index + 1) * _chaptersPerPage).clamp(0, totalChapters);
                        bool isSelected = _currentPageIndex == index;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _currentPageIndex = index;
                            });
                          },
                          child: Container(
                            alignment: Alignment.center,
                            margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: isSelected ? AppConstants.primaryColor : AppConstants.cardDark,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? Colors.transparent : Colors.grey[800]!,
                              ),
                            ),
                            child: Text(
                              '$startChap - $endChap',
                              style: TextStyle(
                                color: isSelected ? Colors.white : AppConstants.textSecondaryDark,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

              // 4. Danh sách chương của Trang được chọn
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    // Tính toán chỉ số chương thực tế
                    final int actualIndex = _currentPageIndex * _chaptersPerPage + index;
                    if (actualIndex >= totalChapters) return null;

                    final chap = widget.novel.chapList[actualIndex];
                    
                    // Kiểm tra xem chương này có phải chương đang đọc không
                    final bool isReading = history != null && history.chapId == chap.id;

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: isReading ? AppConstants.cardDark.withOpacity(0.7) : Colors.transparent,
                        border: Border(
                          bottom: BorderSide(color: Colors.grey[900]!, width: 1),
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        title: Text(
                          chap.ten,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isReading ? AppConstants.primaryColor : AppConstants.textPrimaryDark,
                            fontSize: 15,
                            fontWeight: isReading ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        trailing: Icon(
                          isReading ? Icons.play_arrow_rounded : Icons.arrow_forward_ios_rounded,
                          color: isReading ? AppConstants.primaryColor : Colors.grey[700],
                          size: 16,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ReaderPage(
                                novel: widget.novel,
                                initialChapterIndex: actualIndex,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                  childCount: _chaptersPerPage,
                ),
              ),
              
              // Sliver padding phía cuối
              const SliverToBoxAdapter(
                child: SizedBox(height: 30),
              ),
            ],
          );
        },
      ),
    );
  }
}
