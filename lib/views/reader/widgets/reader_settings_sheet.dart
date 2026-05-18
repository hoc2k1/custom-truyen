import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/reader_provider.dart';
import '../../../utils/constants.dart';

class ReaderSettingsSheet extends StatelessWidget {
  const ReaderSettingsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ReaderProvider>(
      builder: (context, readerProv, child) {
        final settings = readerProv.settings;
        final currentTheme = readerProv.themeModeString;

        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E), // Luôn dùng nền tối cho sheet cài đặt
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thanh kéo drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Cài Đặt Đọc',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // 1. Tùy chỉnh Cỡ Chữ
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Cỡ chữ',
                    style: TextStyle(color: AppConstants.textSecondaryDark, fontSize: 15),
                  ),
                  Row(
                    children: [
                      // Nút Giảm
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey[850],
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.remove_rounded),
                        onPressed: () {
                          readerProv.updateFontSize(settings.fontSize - 1);
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          '${settings.fontSize.toInt()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Nút Tăng
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey[850],
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.add_rounded),
                        onPressed: () {
                          readerProv.updateFontSize(settings.fontSize + 1);
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 2. Tùy chỉnh Giãn Dòng
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Giãn dòng',
                    style: TextStyle(color: AppConstants.textSecondaryDark, fontSize: 15),
                  ),
                  ToggleButtons(
                    isSelected: [
                      settings.lineHeight == 1.2,
                      settings.lineHeight == 1.5,
                      settings.lineHeight == 1.8,
                      settings.lineHeight == 2.0,
                    ],
                    onPressed: (index) {
                      final heights = [1.2, 1.5, 1.8, 2.0];
                      readerProv.updateLineHeight(heights[index]);
                    },
                    borderRadius: BorderRadius.circular(8),
                    selectedColor: Colors.white,
                    fillColor: AppConstants.primaryColor,
                    color: Colors.grey[400],
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 36),
                    children: const [
                      Text('1.2', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('1.5', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('1.8', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('2.0', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 3. Tùy chỉnh Màu Nền (Theme Mode)
              const Text(
                'Màu nền',
                style: TextStyle(color: AppConstants.textSecondaryDark, fontSize: 15),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Nền Tối (Dark)
                  _buildThemeButton(
                    context: context,
                    themeKey: 'dark',
                    currentTheme: currentTheme,
                    label: 'Tối',
                    bgColor: const Color(0xFF121212),
                    textColor: Colors.white,
                    readerProv: readerProv,
                  ),
                  // Nền Giấy Cổ (Sepia)
                  _buildThemeButton(
                    context: context,
                    themeKey: 'sepia',
                    currentTheme: currentTheme,
                    label: 'Cổ điển',
                    bgColor: const Color(0xFFF4ECD8),
                    textColor: const Color(0xFF3C2F2F),
                    readerProv: readerProv,
                  ),
                  // Nền Xám (Gray)
                  _buildThemeButton(
                    context: context,
                    themeKey: 'gray',
                    currentTheme: currentTheme,
                    label: 'Xám',
                    bgColor: const Color(0xFF2D2D2D),
                    textColor: Colors.white,
                    readerProv: readerProv,
                  ),
                  // Nền Sáng (Light)
                  _buildThemeButton(
                    context: context,
                    themeKey: 'light',
                    currentTheme: currentTheme,
                    label: 'Sáng',
                    bgColor: const Color(0xFFF9F9F9),
                    textColor: Colors.black,
                    readerProv: readerProv,
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeButton({
    required BuildContext context,
    required String themeKey,
    required String currentTheme,
    required String label,
    required Color bgColor,
    required Color textColor,
    required ReaderProvider readerProv,
  }) {
    final bool isSelected = currentTheme == themeKey;

    return GestureDetector(
      onTap: () => readerProv.changeThemeMode(themeKey),
      child: Container(
        width: 75,
        height: 60,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppConstants.primaryColor : Colors.grey[800]!,
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppConstants.primaryColor.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
