import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/truyen_model.dart';
import '../../providers/reader_provider.dart';
import '../../utils/constants.dart';
import '../reader/reader_page.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class DetailPage extends StatefulWidget {
  final TruyenModel novel;

  const DetailPage({super.key, required this.novel});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  int _currentPageIndex = 0;
  final int _chaptersPerPage = 100;

  late ItemScrollController _itemScrollController;
  late ItemPositionsListener _itemPositionsListener;

  bool _historyHandled = false;

  @override
  void initState() {
    super.initState();

    _itemScrollController = ItemScrollController();
    _itemPositionsListener = ItemPositionsListener.create();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundDark,
      body: Consumer<ReaderProvider>(
        builder: (context, readerProv, child) {
          final history = readerProv.getHistory(widget.novel.id);
          if (
              !_historyHandled &&
              readerProv.isInitialized &&
              history != null
          ) {
            _historyHandled = true;

            final savedIndex = widget.novel.chapList.indexWhere(
              (c) => c.id == history.chapId,
            );

            if (savedIndex != -1) {
              _currentPageIndex = savedIndex ~/ _chaptersPerPage;

              WidgetsBinding.instance.addPostFrameCallback((_) {
                Future.delayed(
                  const Duration(milliseconds: 200),
                  () {
                    final indexInPage =
                        savedIndex % _chaptersPerPage;

                    if (_itemScrollController.isAttached) {
                      _itemScrollController.jumpTo(
                        index: indexInPage,
                      );
                    }
                  },
                );
              });
            }
          }
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

              // 2. Sticky Header chứa Nút bấm Action và Nút phân trang chương ghim cố định khi cuộn
              SliverAppBar(
                pinned: true,
                primary: false,
                automaticallyImplyLeading: false,
                backgroundColor: AppConstants.backgroundDark,
                titleSpacing: 0,
                toolbarHeight: totalPages > 1 ? 132.0 : 76.0,
                title: _buildStickyHeader(context, history, totalChapters, totalPages),
              ),

              // 4. Danh sách chương của Trang được chọn
              SliverFillRemaining(
                child: ScrollablePositionedList.builder(
                  itemScrollController: _itemScrollController,
                  itemPositionsListener: _itemPositionsListener,
                  itemCount: _chaptersPerPage,
                  itemBuilder: (context, index) {
                    // Tính toán chỉ số chương thực tế
                    final int actualIndex = _currentPageIndex * _chaptersPerPage + index;
                    if (actualIndex >= totalChapters) {
                      return const SizedBox.shrink();
                    }

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
                          maxLines: 10,
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

  // Widget xây dựng giao diện ghim (Sticky)
  Widget _buildStickyHeader(
    BuildContext context,
    dynamic history,
    int totalChapters,
    int totalPages,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Các nút Action (Đọc từ đầu / Đọc tiếp)
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 8),
          child: Row(
            children: [
              // Nút Đọc từ đầu
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppConstants.primaryColor, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: AppConstants.backgroundDark,
                  ),
                  icon: const Icon(Icons.play_circle_outline_rounded, color: AppConstants.primaryColor, size: 20),
                  label: const Text(
                    'Đọc Từ Đầu',
                    style: TextStyle(
                      color: AppConstants.primaryColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    if (widget.novel.chapList.isEmpty) return;

                    void goToReader() {
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

                    if (history != null) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: AppConstants.cardDark,
                          title: const Text(
                            'Đọc lại từ đầu',
                            style: TextStyle(color: Colors.white),
                          ),
                          content: const Text(
                            'Bạn đang đọc dở truyện này. Bắt đầu đọc lại sẽ ghi đè lên tiến trình hiện tại. Bạn có chắc chắn muốn đọc từ đầu không?',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                'Hủy',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppConstants.primaryColor,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {
                                Navigator.pop(context); // Đóng popup
                                goToReader();
                              },
                              child: const Text('Đồng Ý'),
                            ),
                          ],
                        ),
                      );
                    } else {
                      goToReader();
                    }
                  },
                ),
              ),
              // Hiển thị nút "Đọc Tiếp" nếu có lịch sử đọc
              if (history != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.menu_book_rounded, size: 20),
                    label: const Text(
                      'Đọc Tiếp',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
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

        // 2. Thanh phân trang (Chỉ hiển thị nếu tổng trang > 1)
        if (totalPages > 1)
          Container(
            height: 48,
            padding: const EdgeInsets.only(bottom: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: totalPages,
              itemBuilder: (context, index) {
                // Tính toán chỉ số chương thực tế bắt đầu và kết thúc của trang hiện tại
                int startIndex = index * _chaptersPerPage;
                int endIndex = ((index + 1) * _chaptersPerPage - 1).clamp(0, totalChapters - 1);

                // Lấy ID chương thực tế của chương đầu tiên và chương cuối cùng trong trang
                int startChapId = widget.novel.chapList[startIndex].id;
                int endChapId = widget.novel.chapList[endIndex].id;
                
                bool isSelected = _currentPageIndex == index;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentPageIndex = index;
                    });

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_itemScrollController.isAttached) {
                        _itemScrollController.jumpTo(index: 0);
                      }
                    });
                  },
                  child: Container(
                    alignment: Alignment.center,
                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? AppConstants.primaryColor : AppConstants.cardDark,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? Colors.transparent : Colors.grey[850]!,
                      ),
                    ),
                    child: Text(
                      '$startChapId - $endChapId',
                      style: TextStyle(
                        fontSize: 15,
                        color: isSelected ? Colors.white : AppConstants.textSecondaryDark,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
