import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../legal/screens/medical_disclaimer_screen.dart';
import 'mode_selection_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Chào mừng đến với MomCare+',
      description:
          'Người bạn đồng hành giúp bạn theo dõi thai kỳ khỏe mạnh và an tâm hơn.',
      icon: Icons.favorite,
      color: const Color(0xFFFF9A9E),
    ),
    OnboardingPage(
      title: 'Theo dõi hành trình',
      description:
          'Theo dõi thai kỳ theo từng tuần và lưu lại các mốc phát triển quan trọng.',
      icon: Icons.track_changes,
      color: const Color(0xFFFAD0C4),
    ),
    OnboardingPage(
      title: 'Gợi ý dinh dưỡng',
      description:
          'Xem hướng dẫn dinh dưỡng và công thức phù hợp theo từng giai đoạn.',
      icon: Icons.restaurant_menu,
      color: const Color(0xFFFFC3A0),
    ),
    OnboardingPage(
      title: 'Sắp xếp lịch hẹn',
      description:
          'Lưu lịch khám và nhận nhắc nhở để không bỏ lỡ những mốc cần nhớ.',
      icon: Icons.calendar_today,
      color: const Color(0xFFFFB74D),
    ),
    OnboardingPage(
      title: 'Lưu ý y tế',
      description:
          'MomCare+ chỉ cung cấp thông tin tham khảo, không chẩn đoán, điều trị hoặc thay thế bác sĩ.',
      icon: Icons.medical_information,
      color: const Color(0xFF4DB6AC),
      showDisclaimerLink: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => _buildDot(index),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      if (_currentPage > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: const Text('Quay lại'),
                          ),
                        ),
                      if (_currentPage > 0) const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (_currentPage == _pages.length - 1) {
                              _completeOnboarding();
                            } else {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                          child: Text(
                            _currentPage == _pages.length - 1
                                ? 'Bắt đầu'
                                : 'Tiếp tục',
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_currentPage < _pages.length - 1)
                    TextButton(
                      onPressed: _completeOnboarding,
                      child: const Text('Bỏ qua'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: page.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(page.icon, size: 100, color: page.color),
          ),
          const SizedBox(height: 48),
          Text(
            page.title,
            style: Theme.of(
              context,
            ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            page.description,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          if (page.showDisclaimerLink) ...[
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const MedicalDisclaimerScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.article_outlined),
              label: const Text('Đọc tuyên bố miễn trừ'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: _currentPage == index ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? Theme.of(context).primaryColor
            : Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.onboardingKey, true);

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const ModeSelectionScreen()),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool showDisclaimerLink;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.showDisclaimerLink = false,
  });
}
