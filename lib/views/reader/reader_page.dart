import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import '../../models/truyen_model.dart';
import '../../providers/reader_provider.dart';
import '../../utils/constants.dart';
import 'widgets/reader_settings_sheet.dart';

class ReaderPage extends StatefulWidget {
  final TruyenModel novel;
  final int initialChapterIndex;

  const ReaderPage({
    super.key,
    required this.novel,
    required this.initialChapterIndex,
  });

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> with WidgetsBindingObserver {
  late int _currentChapIndex;
  late ScrollController _scrollController;
  bool _isToolbarVisible = true;
  bool _isLoadingChapter = true; // Khởi đầu với trạng thái loading 1s
  final ValueNotifier<double> _progressNotifier = ValueNotifier<double>(0.0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentChapIndex = widget.initialChapterIndex;
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);

    // Tự động khôi phục tiến trình cũ sau khi giả lập loading 1s
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isLoadingChapter = false;
        });
        // Chờ UI render xong (khi _isLoadingChapter = false) rồi mới nhảy tới vị trí scroll
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _restoreProgress();
        });
      }
    });
  }

  @override
  void dispose() {
    // Lưu lịch sử đọc trước khi huỷ trang
    _saveProgress();
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _progressNotifier.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive) {
      _saveProgress();
    }
  }

  // Lắng nghe cuộn màn hình để Ẩn/Hiện thanh công cụ
  double _lastOffset = 0;
  double _lastMaxScroll = 0;
  double _upScrollDistance = 0;

  void _scrollListener() {
    final position = _scrollController.position;
    final currentOffset = position.pixels;

    // progress
    if (_scrollController.hasClients) {
      final maxScroll = position.maxScrollExtent;
      _lastMaxScroll = maxScroll;

      if (maxScroll > 0) {
        _progressNotifier.value = (currentOffset / maxScroll).clamp(0.0, 1.0);
      } else {
        _progressNotifier.value = 0.0;
      }
    }

    // kéo xuống
    if (position.userScrollDirection == ScrollDirection.reverse) {
      _upScrollDistance = 0;

      if (_isToolbarVisible) {
        setState(() {
          _isToolbarVisible = false;
        });
      }
    }
    // kéo lên
    else if (position.userScrollDirection == ScrollDirection.forward) {
      _upScrollDistance += (_lastOffset - currentOffset);

      if (_upScrollDistance >= 100 && !_isToolbarVisible) {
        setState(() {
          _isToolbarVisible = true;
        });
      }
    }

    _lastOffset = currentOffset;
  }

  // Khôi phục vị trí cuộn cũ từ SharedPreferences
  void _restoreProgress() {
    final readerProv = context.read<ReaderProvider>();
    final history = readerProv.getHistory(widget.novel.id);

    // Chỉ khôi phục vị trí nếu đang đọc đúng chương đã lưu
    if (history != null &&
        history.chapId == widget.novel.chapList[_currentChapIndex].id) {
      // Tăng delay nhẹ lên 200ms sau loading để người dùng kịp nhìn thấy hiệu ứng bắt đầu cuộn
      Future.delayed(const Duration(milliseconds: 200), () {
        if (_scrollController.hasClients) {
          final maxScroll = _scrollController.position.maxScrollExtent;
          final targetOffset = history.progress * maxScroll;

          // Lùi lại 150 pixel để xem được bối cảnh nội dung trước đó
          final double adjustedOffset = (targetOffset - 150).clamp(
            0.0,
            maxScroll,
          );

          if (adjustedOffset > 0) {
            // Có hiệu ứng trượt (scroll) mượt mà đến vị trí đang đọc
            _scrollController.animateTo(
              adjustedOffset,
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
            );
          } else {
            _scrollController.jumpTo(0);
          }
        }
      });
    }
  }

  // Tính toán và lưu tiến trình đọc
  void _saveProgress() {
    double currentScroll = 0;
    double maxScroll = 0;

    if (_scrollController.hasClients) {
      currentScroll = _scrollController.position.pixels;
      maxScroll = _scrollController.position.maxScrollExtent;
    } else {
      currentScroll = _lastOffset;
      maxScroll = _lastMaxScroll;
    }

    // Tính % progress dựa trên tỷ lệ scroll (nếu maxScroll = 0 thì progress = 0.0)
    double progressPercent = 0.0;
    if (maxScroll > 0) {
      progressPercent = (currentScroll / maxScroll).clamp(0.0, 1.0);
    }

    final currentChap = widget.novel.chapList[_currentChapIndex];
    context.read<ReaderProvider>().updateHistory(
      widget.novel.id,
      currentChap.id,
      progressPercent,
    );
  }

  // Chuyển chương truyện
  void _changeChapter(int newIndex) {
    if (newIndex < 0 || newIndex >= widget.novel.chapList.length) return;

    setState(() {
      _isLoadingChapter = true;
      _currentChapIndex = newIndex;
      _progressNotifier.value = 0.0; // Reset thanh tiến trình về 0
    });

    // Lưu ngay tiến trình là chương mới (0%)
    final newChap = widget.novel.chapList[newIndex];
    context.read<ReaderProvider>().updateHistory(
      widget.novel.id,
      newChap.id,
      0.0,
    );

    // Cuộn lên đầu trang cho chương mới
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }

    // Giả lập hiệu ứng chuyển trang mượt mà (tăng lên 1s)
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isLoadingChapter = false;
          _isToolbarVisible = true;
        });
      }
    });
  }

  // Mở Bottom Sheet danh sách chương nhanh
  void _showChapterSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return ChapterSelectorSheet(
          novel: widget.novel,
          currentChapIndex: _currentChapIndex,
          onChangeChapter: _changeChapter,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final readerProv = Provider.of<ReaderProvider>(context);
    if (!readerProv.isInitialized) {
      return const Scaffold(
        backgroundColor: AppConstants.backgroundDark,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final settings = readerProv.settings;
    final currentChap = widget.novel.chapList[_currentChapIndex];

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        _saveProgress();
      },
      child: Scaffold(
        backgroundColor: settings.backgroundColor,
        body: Stack(
          children: [
            // 1. Vùng đọc nội dung truyện
            GestureDetector(
              onTap: () {
                // Tap vào giữa màn hình để Ẩn/Hiện thanh công cụ
                setState(() {
                  _isToolbarVisible = !_isToolbarVisible;
                });
              },
              child: _isLoadingChapter
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppConstants.primaryColor,
                      ),
                    )
                  : SafeArea(
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 24,
                        ).copyWith(bottom: 300),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Padding để nội dung không bị che bởi Floating Header khi hiện
                            const SizedBox(height: 56),

                            // Tiêu đề chương lớn trong nội dung đọc
                            Text(
                              currentChap.ten,
                              style: TextStyle(
                                color: settings.textColor,
                                fontSize: settings.fontSize + 4,
                                fontWeight: FontWeight.bold,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Divider(
                              color: settings.textColor.withOpacity(0.15),
                              thickness: 1,
                            ),
                            const SizedBox(height: 20),

                            // Nội dung chữ truyện
                            Text(
                              currentChap.noiDung,
                              style: TextStyle(
                                color: settings.textColor,
                                fontSize: settings.fontSize,
                                height: settings.lineHeight,
                                letterSpacing: 0.2,
                              ),
                            ),

                            const SizedBox(height: 40),
                            // Nút chuyển chương ở cuối bài đọc
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey[850],
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: _currentChapIndex > 0
                                      ? () => _changeChapter(
                                          _currentChapIndex - 1,
                                        )
                                      : null,
                                  child: const Text('Chương Trước'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppConstants.primaryColor,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed:
                                      _currentChapIndex <
                                          widget.novel.chapList.length - 1
                                      ? () => _changeChapter(
                                          _currentChapIndex + 1,
                                        )
                                      : null,
                                  child: const Text('Chương Sau'),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 80,
                            ), // Chừa không gian tránh Footer che
                          ],
                        ),
                      ),
                    ),
            ),

            // 2. Floating Header (Slide từ trên xuống)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              top: _isToolbarVisible
                  ? 0
                  : -130, // Ẩn hoàn toàn lên trên khi false
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: AppConstants.cardDark.withOpacity(0.95),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Thanh điều hướng AppBar chính
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              _saveProgress();
                              Navigator.pop(context);
                            },
                          ),
                          Expanded(
                            child: Text(
                              currentChap.ten,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.settings_rounded,
                              color: AppConstants.primaryColor,
                            ),
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: Colors.transparent,
                                builder: (context) =>
                                    const ReaderSettingsSheet(),
                              );
                            },
                          ),
                        ],
                      ),
                      // Thanh Breadcrumb cao cấp
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          bottom: 8,
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                _saveProgress();
                                Navigator.popUntil(
                                  context,
                                  (route) => route.isFirst,
                                );
                              },
                              child: const Text(
                                'Trang chủ',
                                style: TextStyle(
                                  color: AppConstants.accentColor,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.grey,
                              size: 14,
                            ),
                            GestureDetector(
                              onTap: () {
                                _saveProgress();
                                Navigator.pop(context);
                              },
                              child: Text(
                                widget.novel.ten,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppConstants.accentColor,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.grey,
                              size: 14,
                            ),
                            Expanded(
                              child: Text(
                                'Chương ${currentChap.id}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 3. Floating Footer (Slide từ dưới lên)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              bottom: _isToolbarVisible
                  ? 0
                  : -100, // Ẩn hoàn toàn xuống dưới khi false
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: AppConstants.cardDark.withOpacity(0.95),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.only(top: 8, bottom: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Nút chương trước
                    IconButton(
                      icon: const Icon(
                        Icons.navigate_before_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                      onPressed: _currentChapIndex > 0
                          ? () => _changeChapter(_currentChapIndex - 1)
                          : null,
                    ),
                    // Nút mở danh sách chương
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[850],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      icon: const Icon(
                        Icons.format_list_bulleted_rounded,
                        size: 18,
                      ),
                      label: const Text('Mục Lục'),
                      onPressed: _showChapterSelector,
                    ),
                    // Nút chương sau
                    IconButton(
                      icon: const Icon(
                        Icons.navigate_next_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                      onPressed:
                          _currentChapIndex < widget.novel.chapList.length - 1
                          ? () => _changeChapter(_currentChapIndex + 1)
                          : null,
                    ),
                  ],
                ),
              ),
            ),

            // 4. Thanh tiến trình đọc siêu mỏng cố định ở trên đầu trang
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: ValueListenableBuilder<double>(
                  valueListenable: _progressNotifier,
                  builder: (context, progress, child) {
                    return Container(
                      height: 3, // Chiều cao siêu mỏng sang trọng
                      width: double.infinity,
                      color: settings.textColor.withOpacity(
                        0.08,
                      ), // Nền mờ của thanh progress
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: progress,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppConstants.textSecondaryDark.withOpacity(
                                0.6,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ), // Đóng Stack
      ), // Đóng Scaffold
    ); // Đóng PopScope
  }
}

class ChapterSelectorSheet extends StatefulWidget {
  final TruyenModel novel;
  final int currentChapIndex;
  final Function(int) onChangeChapter;

  const ChapterSelectorSheet({
    super.key,
    required this.novel,
    required this.currentChapIndex,
    required this.onChangeChapter,
  });

  @override
  State<ChapterSelectorSheet> createState() => _ChapterSelectorSheetState();
}

class _ChapterSelectorSheetState extends State<ChapterSelectorSheet> {
  late int _currentPageIndex;
  final int _chaptersPerPage = 100;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _currentPageIndex = widget.currentChapIndex ~/ _chaptersPerPage;
    
    // Ước lượng chiều cao mỗi item (ListTile mặc định khoảng 56.0).
    int indexInPage = widget.currentChapIndex % _chaptersPerPage;
    double initialOffset = indexInPage * 56.0; 
    
    _scrollController = ScrollController(initialScrollOffset: initialOffset);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalChapters = widget.novel.chapList.length;
    final int totalPages = (totalChapters / _chaptersPerPage).ceil();

    return Container(
      padding: const EdgeInsets.only(left: 16, right: 8, top: 20, bottom: 20),
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: Text(
              'Danh Sách Chương',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Phân trang giống trang chi tiết
          if (totalPages > 1)
            Container(
              height: 40,
              margin: const EdgeInsets.only(bottom: 12),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: totalPages,
                itemBuilder: (context, index) {
                  int startIndex = index * _chaptersPerPage;
                  int endIndex = ((index + 1) * _chaptersPerPage - 1)
                      .clamp(0, totalChapters - 1);
                  int startChapId = widget.novel.chapList[startIndex].id;
                  int endChapId = widget.novel.chapList[endIndex].id;
                  bool isSelected = _currentPageIndex == index;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _currentPageIndex = index;
                        // Khi đổi trang thì cuộn lên đầu danh sách chương
                        _scrollController.jumpTo(0);
                      });
                    },
                    child: Container(
                      alignment: Alignment.center,
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppConstants.primaryColor
                            : AppConstants.cardDark,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : Colors.grey[850]!,
                        ),
                      ),
                      child: Text(
                        '$startChapId - $endChapId',
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AppConstants.textSecondaryDark,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          Expanded(
            child: RawScrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              thumbColor: AppConstants.primaryColor.withOpacity(0.5),
              thickness: 4,
              radius: const Radius.circular(10),
              crossAxisMargin: 2,
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _chaptersPerPage,
                itemBuilder: (context, index) {
                  final int actualIndex =
                      _currentPageIndex * _chaptersPerPage + index;
                  if (actualIndex >= totalChapters) return null;

                  final chap = widget.novel.chapList[actualIndex];
                  final isCurrent = actualIndex == widget.currentChapIndex;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    title: Text(
                      chap.ten,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isCurrent
                            ? AppConstants.primaryColor
                            : Colors.grey[300],
                        fontWeight: isCurrent
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    trailing: isCurrent
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: AppConstants.primaryColor,
                          )
                        : null,
                    onTap: () {
                      Navigator.pop(context);
                      widget.onChangeChapter(actualIndex);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
