import 'package:flutter/material.dart';

class GenderSelectionScreen extends StatelessWidget {
  const GenderSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gender Selection Information'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Disclaimer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                border: Border.all(color: Colors.orange, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text(
                        'IMPORTANT DISCLAIMER',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'The information below is for educational purposes only and based on various theories like the Shettles Method. '
                    'There is NO guaranteed method to select baby gender naturally. '
                    'These methods may increase probability but are NOT scientifically proven to be 100% effective. '
                    'Always consult with your healthcare provider before trying any method.',
                    style: TextStyle(height: 1.5),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Introduction
            Text(
              'Gender Selection Methods',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Several theories suggest that timing, diet, and other factors may influence the probability of conceiving a boy or girl. '
              'The most well-known is the Shettles Method, based on differences between X (girl) and Y (boy) sperm chromosomes.',
              style: TextStyle(height: 1.5),
            ),

            const SizedBox(height: 24),

            // Boy Section
            _buildGenderCard(
              theme: theme,
              icon: Icons.male,
              iconColor: Colors.blue,
              title: 'Methods for Conceiving a Boy',
              subtitle: 'Y-chromosome sperm characteristics: Faster, less resilient',
              methods: [
                _GenderMethod(
                  icon: Icons.schedule,
                  title: 'Timing',
                  description:
                      'Have intercourse as close to ovulation as possible (on ovulation day or 12 hours before). '
                      'Y-sperm swim faster but die quicker, so timing close to ovulation gives them advantage.',
                ),
                _GenderMethod(
                  icon: Icons.restaurant,
                  title: 'Diet - Alkaline Environment',
                  description:
                      'Foods rich in sodium and potassium may create alkaline environment favorable for Y-sperm:\n'
                      '• Red meat, fish, poultry\n'
                      '• Salty foods (in moderation)\n'
                      '• Bananas, sweet potatoes\n'
                      '• Mushrooms, broccoli\n'
                      '• Citrus fruits',
                ),
                _GenderMethod(
                  icon: Icons.favorite,
                  title: 'Sexual Position',
                  description:
                      'Deep penetration positions (rear-entry) deposit sperm closer to cervix, '
                      'giving faster Y-sperm shorter distance to travel.',
                ),
                _GenderMethod(
                  icon: Icons.calendar_today,
                  title: 'Abstinence Period',
                  description:
                      'Abstain from intercourse for 4-5 days before ovulation to increase sperm count, '
                      'potentially increasing Y-sperm concentration.',
                ),
                _GenderMethod(
                  icon: Icons.thermostat,
                  title: 'Temperature',
                  description:
                      'Some theories suggest keeping testicles cool (loose underwear, avoid hot baths) '
                      'may favor Y-sperm production, though evidence is limited.',
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Girl Section
            _buildGenderCard(
              theme: theme,
              icon: Icons.female,
              iconColor: Colors.pink,
              title: 'Methods for Conceiving a Girl',
              subtitle: 'X-chromosome sperm characteristics: Slower, more resilient',
              methods: [
                _GenderMethod(
                  icon: Icons.schedule,
                  title: 'Timing',
                  description:
                      'Have intercourse 2-4 days BEFORE ovulation, then abstain until 1 day after. '
                      'X-sperm survive longer in reproductive tract, so early timing allows Y-sperm to die off before egg is released.',
                ),
                _GenderMethod(
                  icon: Icons.restaurant,
                  title: 'Diet - Acidic Environment',
                  description:
                      'Foods rich in calcium and magnesium may create acidic environment favorable for X-sperm:\n'
                      '• Dairy products (milk, cheese, yogurt)\n'
                      '• Eggs\n'
                      '• Green leafy vegetables (spinach, kale)\n'
                      '• Nuts and seeds (almonds, sunflower seeds)\n'
                      '• Whole grains (oats, brown rice)',
                ),
                _GenderMethod(
                  icon: Icons.favorite,
                  title: 'Sexual Position',
                  description:
                      'Shallow penetration positions (missionary) deposit sperm farther from cervix, '
                      'making Y-sperm less likely to reach egg first due to longer journey.',
                ),
                _GenderMethod(
                  icon: Icons.calendar_today,
                  title: 'Frequency',
                  description:
                      'Have intercourse frequently (every other day) from period end until 2-3 days before ovulation, '
                      'then stop. This may reduce Y-sperm concentration.',
                ),
                _GenderMethod(
                  icon: Icons.science,
                  title: 'pH Level',
                  description:
                      'Slightly acidic vaginal pH may favor X-sperm. Avoid using alkaline douches. '
                      'Natural pH varies by individual and diet may influence it.',
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Scientific Evidence
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.science, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'Scientific Evidence',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'The Shettles Method claims 75-90% success rate, but scientific studies have shown mixed results. '
                    'Some research supports timing effects, but evidence for diet and position methods is limited. '
                    'The natural probability is approximately 50/50 for each gender. '
                    'These methods may slightly shift probabilities but cannot guarantee results.',
                    style: TextStyle(height: 1.5),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Medical Options
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.local_hospital, color: Colors.purple),
                      const SizedBox(width: 8),
                      Text(
                        'Medical Gender Selection',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'For near 100% accuracy, medical procedures exist:\n\n'
                    '• PGD (Preimplantation Genetic Diagnosis): Used with IVF, tests embryos before implantation. Nearly 100% accurate but expensive and ethically debated.\n\n'
                    '• Sperm Sorting (MicroSort): Separates X and Y sperm, then used with IUI or IVF. 70-90% accuracy depending on gender desired.\n\n'
                    'These methods are primarily for medical reasons (genetic diseases) and may not be available or legal for social gender selection in all countries.',
                    style: TextStyle(height: 1.5),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Final Note
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.favorite, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        'Most Important',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Remember that the most important outcome is a healthy baby, regardless of gender. '
                    'Love and prepare for your baby no matter what. '
                    'Gender disappointment is real but healthy babies are a blessing. '
                    'Focus on your health, proper nutrition, and prenatal care for the best pregnancy outcomes.',
                    style: TextStyle(height: 1.5, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderCard({
    required ThemeData theme,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required List<_GenderMethod> methods,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 32, color: iconColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: iconColor,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...methods.map((method) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildMethodItem(method, theme),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodItem(_GenderMethod method, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(method.icon, size: 20, color: theme.primaryColor),
            const SizedBox(width: 8),
            Text(
              method.title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 28),
          child: Text(
            method.description,
            style: const TextStyle(height: 1.5),
          ),
        ),
      ],
    );
  }
}

class _GenderMethod {
  final IconData icon;
  final String title;
  final String description;

  _GenderMethod({
    required this.icon,
    required this.title,
    required this.description,
  });
}
