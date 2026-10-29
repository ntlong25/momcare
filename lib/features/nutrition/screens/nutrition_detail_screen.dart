import 'package:flutter/material.dart';
import '../../../core/theme/chip_colors.dart';
import '../../../core/data/medical_references.dart';
import '../../../core/models/nutrition_model.dart';
import '../../references/widgets/source_metadata_card.dart';
import '../../../core/theme/app_tokens.dart';

class NutritionDetailScreen extends StatelessWidget {
  final NutritionModel nutrition;

  const NutritionDetailScreen({super.key, required this.nutrition});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hướng dẫn dinh dưỡng')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      nutrition.category,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    nutrition.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tổng quan',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    nutrition.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Lợi ích',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  ...nutrition.benefits.map((benefit) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: context.semantic.success,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              benefit,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 32),
                  Text(
                    'Thực phẩm được khuyến nghị',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: nutrition.recommendedFoods.map((food) {
                      return Chip(
                        label: Text(food),
                        backgroundColor: ChipColors.positiveBackground(context),
                        labelStyle: TextStyle(
                          color: ChipColors.positiveText(context),
                        ),
                      );
                    }).toList(),
                  ),
                  if (nutrition.foodsToAvoid != null &&
                      nutrition.foodsToAvoid!.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    Text(
                      'Thực phẩm nên tránh',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: nutrition.foodsToAvoid!.map((food) {
                        return Chip(
                          label: Text(food),
                          backgroundColor: ChipColors.negativeBackground(
                            context,
                          ),
                          labelStyle: TextStyle(
                            color: ChipColors.negativeText(context),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 32),
                  const SourceMetadataCard(
                    group: MedicalReferenceGroup.nutrition,
                    note:
                        'Thông tin dinh dưỡng mang tính tham khảo chung. Hãy trao đổi với bác sĩ hoặc chuyên gia dinh dưỡng nếu bạn có bệnh nền, dị ứng, thai kỳ nguy cơ cao hoặc nhu cầu ăn uống đặc biệt.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
