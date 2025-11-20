import 'package:flutter/material.dart';

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
      title: 'Chào mừng đến MomCare+',
      description:
          'Ứng dụng đồng hành cùng bạn trong hành trình mang thai khỏe mạnh và hạnh phúc. '
          'Theo dõi tiến trình, quản lý lịch hẹn và nhận tư vấn dinh dưỡng cá nhân hóa.',
      color: Colors.pink,
    ),
    _GuidePage(
      icon: Icons.track_changes,
      title: 'Theo dõi tiến trình',
      description:
          'Theo dõi thai kỳ từng tuần với thông tin chi tiết. '
          'Xem sự phát triển của bé, theo dõi cân nặng và đếm ngược ngày dự sinh.',
      color: Colors.purple,
    ),
    _GuidePage(
      icon: Icons.favorite_border,
      title: 'Nhật ký sức khỏe',
      description:
          'Ghi lại các chỉ số sức khỏe hàng ngày bao gồm cân nặng, huyết áp, đường huyết '
          'và triệu chứng. Lưu trữ nhật ký sức khỏe thai kỳ toàn diện.',
      color: Colors.red,
    ),
    _GuidePage(
      icon: Icons.calendar_today,
      title: 'Lịch hẹn',
      description:
          'Không bỏ lỡ bất kỳ cuộc hẹn nào. Lên lịch và quản lý tất cả các lần khám thai, '
          'siêu âm và kiểm tra y tế tại một nơi với nhắc nhở.',
      color: Colors.blue,
    ),
    _GuidePage(
      icon: Icons.restaurant_menu,
      title: 'Dinh dưỡng & Công thức',
      description:
          'Nhận hướng dẫn dinh dưỡng cá nhân hóa cho từng tam cá nguyệt. '
          'Khám phá các công thức nấu ăn lành mạnh và tìm hiểu thực phẩm nên ăn hoặc tránh.',
      color: Colors.orange,
    ),
    _GuidePage(
      icon: Icons.settings,
      title: 'Tùy chỉnh trải nghiệm',
      description:
          'Cá nhân hóa ứng dụng với chế độ tối, ngôn ngữ và quản lý thông tin thai kỳ. '
          'Dữ liệu của bạn được lưu trữ an toàn và mã hóa trên thiết bị.',
      color: Colors.teal,
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
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Bỏ qua'),
              ),
            ),

            // Page view
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

            // Page indicators
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

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Previous button
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

                  // Next/Done button
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
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with gradient background
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  page.color,
                  page.color.withValues(alpha: 0.6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: page.color.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              page.icon,
              size: 70,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 48),

          // Title
          Text(
            page.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: page.color,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Description
          Text(
            page.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.6,
                ),
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
            ? Theme.of(context).primaryColor
            : Theme.of(context).primaryColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _GuidePage {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  _GuidePage({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
