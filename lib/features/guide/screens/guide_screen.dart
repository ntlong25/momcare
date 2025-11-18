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
      title: 'Welcome to MomCare+',
      description:
          'Your all-in-one companion for a healthy and happy pregnancy journey. '
          'Track your progress, manage appointments, and get personalized nutrition advice.',
      color: Colors.pink,
    ),
    _GuidePage(
      icon: Icons.track_changes,
      title: 'Track Your Progress',
      description:
          'Monitor your pregnancy week by week with detailed insights. '
          'View your baby\'s development, track weight gain, and see how many days until your due date.',
      color: Colors.purple,
    ),
    _GuidePage(
      icon: Icons.favorite_border,
      title: 'Health Diary',
      description:
          'Record your daily health metrics including weight, blood pressure, blood sugar, '
          'and symptoms. Keep a comprehensive log of your pregnancy health.',
      color: Colors.red,
    ),
    _GuidePage(
      icon: Icons.calendar_today,
      title: 'Appointments',
      description:
          'Never miss a doctor\'s appointment. Schedule and manage all your prenatal visits, '
          'ultrasounds, and medical checkups in one place with reminders.',
      color: Colors.blue,
    ),
    _GuidePage(
      icon: Icons.restaurant_menu,
      title: 'Nutrition & Recipes',
      description:
          'Get personalized nutrition guidance for each trimester. '
          'Discover healthy recipes, track your daily intake, and learn what foods to eat or avoid.',
      color: Colors.orange,
    ),
    _GuidePage(
      icon: Icons.settings,
      title: 'Customize Your Experience',
      description:
          'Personalize the app with dark mode, language preferences, and manage your pregnancy information. '
          'Your data is stored securely and encrypted on your device.',
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
                child: const Text('Skip'),
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
                      label: const Text('Previous'),
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
                      _currentPage < _pages.length - 1 ? 'Next' : 'Get Started',
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
