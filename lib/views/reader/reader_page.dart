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

class _ReaderPageState extends State<ReaderPage> {
  late int _currentChapIndex;
  late ScrollController _scrollController;
  bool _isToolbarVisible = true;
  bool _isLoadingChapter = false;

  @override
  void initState() {
    super.initState();
    _currentChapIndex = widget.initialChapterIndex;
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    
    // Tự động khôi phục tiến trình cũ khi mở trang
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreProgress();
    });
  }

  @override
  void dispose() {
    // Lưu lịch sử đọc trước khi huỷ trang
    _saveProgress();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  // Lắng nghe cuộn màn hình để Ẩn/Hiện thanh công cụ
  void _scrollListener() {
    if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
      if (_isToolbarVisible) {
        setState(() {
          _isToolbarVisible = false;
        });
      }
    } else if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
      if (!_isToolbarVisible) {
        setState(() {
          _isToolbarVisible = true;
        });
      }
    }
  }

  // Khôi phục vị trí cuộn cũ từ SharedPreferences
  void _restoreProgress() {
    final readerProv = context.read<ReaderProvider>();
    final history = readerProv.getHistory(widget.novel.id);
    
    // Chỉ khôi phục vị trí nếu đang đọc đúng chương đã lưu
    if (history != null && history.chapId == widget.novel.chapList[_currentChapIndex].id) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (_scrollController.hasClients) {
          final maxScroll = _scrollController.position.maxScrollExtent;
          final targetOffset = history.progress * maxScroll;
          _scrollController.jumpTo(targetOffset);
        }
      });
    }
  }

  // Tính toán và lưu tiến trình đọc
  void _saveProgress() {
    if (!_scrollController.hasClients) return;
    
    final double maxScroll = _scrollController.position.maxScrollExtent;
    final double currentScroll = _scrollController.position.pixels;
    
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

    // Lưu tiến trình của chương hiện tại trước
    _saveProgress();

    setState(() {
      _isLoadingChapter = true;
      _currentChapIndex = newIndex;
    });

    // Cuộn lên đầu trang cho chương mới
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }

    // Giả lập hiệu ứng chuyển trang mượt mà
    Future.delayed(const Duration(milliseconds: 100), () {
      setState(() {
        _isLoadingChapter = false;
        _isToolbarVisible = true;
      });
      // Lưu luôn lịch sử chương mới ở 0%
      _saveProgress();
    });
  }

  // Mở Bottom Sheet danh sách chương nhanh
  void _showChapterSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Danh Sách Chương',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: widget.novel.chapList.length,
                  itemBuilder: (context, index) {
                    final chap = widget.novel.chapList[index];
                    final isCurrent = index == _currentChapIndex;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      title: Text(
                        chap.ten,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isCurrent ? AppConstants.primaryColor : Colors.grey[300],
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      trailing: isCurrent 
                          ? const Icon(Icons.check_circle_rounded, color: AppConstants.primaryColor)
                          : null,
                      onTap: () {
                        Navigator.pop(context);
                        _changeChapter(index);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
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

    return Scaffold(
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
                ? const Center(child: CircularProgressIndicator(color: AppConstants.primaryColor))
                : SafeArea(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
                          Divider(color: settings.textColor.withOpacity(0.15), thickness: 1),
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
                                    ? () => _changeChapter(_currentChapIndex - 1)
                                    : null,
                                child: const Text('Chương Trước'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppConstants.primaryColor,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: _currentChapIndex < widget.novel.chapList.length - 1
                                    ? () => _changeChapter(_currentChapIndex + 1)
                                    : null,
                                child: const Text('Chương Sau'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 80), // Chừa không gian tránh Footer che
                        ],
                      ),
                    ),
                  ),
          ),

          // 2. Floating Header (Slide từ trên xuống)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            top: _isToolbarVisible ? 0 : -130, // Ẩn hoàn toàn lên trên khi false
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
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
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
                          icon: const Icon(Icons.settings_rounded, color: AppConstants.primaryColor),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.transparent,
                              builder: (context) => const ReaderSettingsSheet(),
                            );
                          },
                        ),
                      ],
                    ),
                    // Thanh Breadcrumb cao cấp
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              _saveProgress();
                              Navigator.popUntil(context, (route) => route.isFirst);
                            },
                            child: const Text(
                              'Trang chủ',
                              style: TextStyle(color: AppConstants.accentColor, fontSize: 12),
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 14),
                          GestureDetector(
                            onTap: () {
                              _saveProgress();
                              Navigator.pop(context);
                            },
                            child: Text(
                              widget.novel.ten,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppConstants.accentColor, fontSize: 12),
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 14),
                          Expanded(
                            child: Text(
                              'Chương ${currentChap.id}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
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
            bottom: _isToolbarVisible ? 0 : -100, // Ẩn hoàn toàn xuống dưới khi false
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
                    icon: const Icon(Icons.navigate_before_rounded, color: Colors.white, size: 32),
                    onPressed: _currentChapIndex > 0
                        ? () => _changeChapter(_currentChapIndex - 1)
                        : null,
                  ),
                  // Nút mở danh sách chương
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[850],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    icon: const Icon(Icons.format_list_bulleted_rounded, size: 18),
                    label: const Text('Mục Lục'),
                    onPressed: _showChapterSelector,
                  ),
                  // Nút chương sau
                  IconButton(
                    icon: const Icon(Icons.navigate_next_rounded, color: Colors.white, size: 32),
                    onPressed: _currentChapIndex < widget.novel.chapList.length - 1
                        ? () => _changeChapter(_currentChapIndex + 1)
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
