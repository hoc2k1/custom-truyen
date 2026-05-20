import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/novel_provider.dart';
import '../../providers/reader_provider.dart';
import '../../utils/constants.dart';
import '../detail/detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Tải dữ liệu truyện khi mở ứng dụng
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NovelProvider>().loadNovels();
    });
  }

  Future<void> _handleUpload() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null && result.files.single.path != null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đang xử lý file...'),
            duration: Duration(seconds: 1),
          ),
        );
        
        await context.read<NovelProvider>().importCustomData(result.files.single.path!);
        
        if (context.mounted) {
          final error = context.read<NovelProvider>().errorMessage;
          if (error.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error), backgroundColor: Colors.red),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tải file thành công!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppConstants.cardDark,
        elevation: 2,
        title: const Row(
          children: [
            Icon(Icons.menu_book_rounded, color: AppConstants.primaryColor),
            SizedBox(width: 10),
            Text(
              'Custom Truyện',
              style: TextStyle(
                color: AppConstants.textPrimaryDark,
                fontWeight: FontWeight.bold,
                fontSize: 22,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: AppConstants.textSecondaryDark),
            onPressed: () {
              // Tính năng tìm kiếm mở rộng (nếu cần)
            },
          ),
        ],
      ),
      body: _selectedIndex == 0 ? _buildHomeTab() : _buildUploadTab(),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppConstants.cardDark,
        selectedItemColor: AppConstants.primaryColor,
        unselectedItemColor: AppConstants.textSecondaryDark,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.upload_file_rounded),
            label: 'Upload',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return Consumer2<NovelProvider, ReaderProvider>(
      builder: (context, novelProv, readerProv, child) {
          if (novelProv.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
              ),
            );
          }

          if (novelProv.errorMessage.isNotEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 60, color: Colors.redAccent),
                    const SizedBox(height: 15),
                    Text(
                      novelProv.errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => novelProv.loadNovels(),
                      child: const Text('Thử Lại'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (novelProv.novels.isEmpty) {
            return const Center(
              child: Text(
                'Không tìm thấy truyện nào.',
                style: TextStyle(color: AppConstants.textSecondaryDark, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: novelProv.novels.length,
            itemBuilder: (context, index) {
              final truyen = novelProv.novels[index];
              final history = readerProv.getHistory(truyen.id);
              final totalChapters = truyen.totalChapters;
              
              // Tính tiến trình đọc
              String progressText = 'Chưa đọc (0 / $totalChapters)';
              double progressPercent = 0.0;
              
              if (history != null) {
                // Lấy chỉ số chương và %
                progressPercent = (history.chapId / totalChapters).clamp(0.0, 1.0);
                progressText = 'Đang đọc: Chương ${history.chapId} / $totalChapters (${(progressPercent * 100).toStringAsFixed(1)}%)';
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppConstants.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailPage(novel: truyen),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Ảnh bìa truyện (logo mặc định)
                            Container(
                              width: 85,
                              height: 110,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                image: const DecorationImage(
                                  image: AssetImage(AppConstants.logoPath),
                                  fit: BoxFit.cover,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.4),
                                    blurRadius: 4,
                                    offset: const Offset(2, 2),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            // Thông tin truyện
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    truyen.ten,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppConstants.textPrimaryDark,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    progressText,
                                    style: const TextStyle(
                                      color: AppConstants.textSecondaryDark,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // ProgressBar neon
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: LinearProgressIndicator(
                                      value: progressPercent,
                                      minHeight: 6,
                                      backgroundColor: Colors.grey[800],
                                      valueColor: const AlwaysStoppedAnimation<Color>(
                                        AppConstants.primaryColor,
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
                ),
              );
            },
          );
        },
      );
  }

  Widget _buildUploadTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_upload_rounded, size: 80, color: AppConstants.primaryColor),
          const SizedBox(height: 20),
          const Text(
            'Tải lên file dữ liệu JSON của bạn',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.upload_file_rounded),
            label: const Text(
              'Chọn File JSON',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            onPressed: _handleUpload,
          ),
        ],
      ),
    );
  }
}
