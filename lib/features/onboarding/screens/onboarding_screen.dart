import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../legal/screens/medical_disclaimer_screen.dart';
import 'mode_selection_screen.dart';
import '../../../core/theme/app_tokens.dart';

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
      tone: AppTone.primary,
    ),
    OnboardingPage(
      title: 'Theo dõi hành trình',
      description:
          'Theo dõi thai kỳ theo từng tuần và lưu lại các mốc phát triển quan trọng.',
      icon: Icons.track_changes,
      tone: AppTone.secondary,
    ),
    OnboardingPage(
      title: 'Gợi ý dinh dưỡng',
      description:
          'Xem hướng dẫn dinh dưỡng và công thức phù hợp theo từng giai đoạn.',
      icon: Icons.restaurant_menu,
      tone: AppTone.tertiary,
    ),
    OnboardingPage(
      title: 'Sắp xếp lịch hẹn',
      description:
          'Lưu lịch khám và nhận nhắc nhở để không bỏ lỡ những mốc cần nhớ.',
      icon: Icons.calendar_today,
      tone: AppTone.primary,
    ),
    OnboardingPage(
      title: 'Lưu ý y tế',
      description:
          'MomCare+ chỉ cung cấp thông tin tham khảo, không chẩn đoán, điều trị hoặc thay thế bác sĩ.',
      icon: Icons.medical_information,
      tone: AppTone.secondary,
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
    // Scrolls when the page is taller than the viewport (small screens,
    // large font scale); stays centred otherwise.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.all(40.0),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: (constraints.maxHeight - 80).clamp(0.0, double.infinity),
          ),
          child: _buildPageContent(page),
        ),
      ),
    );
  }

  Widget _buildPageContent(OnboardingPage page) {
    final colors = page.tone.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: colors.container,
              shape: BoxShape.circle,
            ),
            child: Icon(page.icon, size: 100, color: colors.onContainer),
          ),
          const SizedBox(height: 48),
          Text(
            page.title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
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
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.outlineVariant,
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

  /// Colour family of the page illustration.
  final AppTone tone;
  final bool showDisclaimerLink;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.tone,
    this.showDisclaimerLink = false,
  });
}
