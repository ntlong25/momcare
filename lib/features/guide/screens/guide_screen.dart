import 'package:flutter/material.dart';
import '../../../core/theme/app_tokens.dart';

class GuideScreen extends StatefulWidget {
  const GuideScreen({super.key});

  @override
  State<GuideScreen> createState() => _GuideScreenState();
}

class _GuideScreenState extends State<GuideScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_GuidePage> _pages = [
    _GuidePage(
      icon: Icons.favorite,
      title: 'Chào mừng đến với MomCare+',
      description:
          'Ứng dụng đồng hành cùng bạn trong hành trình chuẩn bị mang thai và thai kỳ. '
          'Bạn có thể theo dõi tiến trình, quản lý lịch hẹn và xem gợi ý dinh dưỡng.',
      tone: AppTone.primary,
    ),
    _GuidePage(
      icon: Icons.track_changes,
      title: 'Theo dõi thai kỳ',
      description:
          'Theo dõi thai kỳ theo từng tuần, xem mốc phát triển của bé, ghi nhận cân nặng '
          'và đếm ngược đến ngày dự sinh.',
      tone: AppTone.secondary,
    ),
    _GuidePage(
      icon: Icons.favorite_border,
      title: 'Nhật ký sức khỏe',
      description:
          'Ghi lại cân nặng, huyết áp, tâm trạng, triệu chứng và ghi chú hằng ngày để bạn '
          'có cái nhìn rõ hơn về sức khỏe của mình.',
      tone: AppTone.primary,
    ),
    _GuidePage(
      icon: Icons.calendar_today,
      title: 'Lịch hẹn',
      description:
          'Lưu lịch khám, địa điểm, bác sĩ và ghi chú để dễ chuẩn bị trước mỗi lần thăm khám.',
      tone: AppTone.secondary,
    ),
    _GuidePage(
      icon: Icons.restaurant_menu,
      title: 'Dinh dưỡng và công thức',
      description:
          'Xem hướng dẫn dinh dưỡng theo giai đoạn và các công thức món ăn lành mạnh.',
      tone: AppTone.info,
    ),
    _GuidePage(
      icon: Icons.settings,
      title: 'Cài đặt',
      description:
          'Tùy chỉnh chế độ sáng/tối, chế độ ứng dụng và thông tin thai kỳ. Dữ liệu v1 được lưu trên thiết bị.',
      tone: AppTone.secondary,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Bỏ qua'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => _buildIndicator(index == _currentPage),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    TextButton.icon(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Trước'),
                    )
                  else
                    const SizedBox(width: 100),
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage < _pages.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    child: Text(
                      _currentPage < _pages.length - 1 ? 'Tiếp' : 'Bắt đầu',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(_GuidePage page) {
    final colors = page.tone.of(context);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: colors.main,
              shape: BoxShape.circle,
            ),
            child: Icon(page.icon, size: 70, color: colors.onMain),
          ),
          const SizedBox(height: 48),
          Text(
            page.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.main,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            page.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _GuidePage {
  final IconData icon;
  final String title;
  final String description;
  final AppTone tone;

  _GuidePage({
    required this.icon,
    required this.title,
    required this.description,
    required this.tone,
  });
}
