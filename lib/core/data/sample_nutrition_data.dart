import 'package:uuid/uuid.dart';
import '../models/nutrition_model.dart';
import '../models/recipe_model.dart';

class SampleNutritionData {
  static List<NutritionModel> getNutritionGuides() {
    return [
      NutritionModel(
        id: const Uuid().v4(),
        title: 'Axit folic trong giai đoạn đầu thai kỳ',
        category: 'Tam cá nguyệt 1',
        description:
            'Axit folic là dưỡng chất thường được khuyến nghị trước và trong giai đoạn đầu thai kỳ. Bạn nên trao đổi với bác sĩ để biết liều phù hợp.',
        benefits: [
          'Hỗ trợ quá trình tạo tế bào mới',
          'Góp phần hỗ trợ phát triển hệ thần kinh của thai nhi',
          'Có thể được bác sĩ khuyến nghị bổ sung trước khi mang thai',
          'Hỗ trợ tạo hồng cầu',
        ],
        recommendedFoods: [
          'Rau lá xanh',
          'Ngũ cốc tăng cường vi chất',
          'Các loại đậu',
          'Trái cây họ cam quýt',
          'Bơ',
        ],
        foodsToAvoid: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      NutritionModel(
        id: const Uuid().v4(),
        title: 'Thực phẩm giàu sắt',
        category: 'Tam cá nguyệt 2',
        description:
            'Sắt hỗ trợ quá trình tạo máu và vận chuyển oxy. Nhu cầu sắt có thể tăng trong thai kỳ, vì vậy bạn nên hỏi bác sĩ khi cần bổ sung.',
        benefits: [
          'Hỗ trợ tạo máu',
          'Góp phần duy trì năng lượng',
          'Hỗ trợ sự phát triển của thai nhi',
          'Hỗ trợ vận chuyển oxy',
        ],
        recommendedFoods: [
          'Thịt nạc',
          'Gia cầm',
          'Cá phù hợp cho thai kỳ',
          'Các loại đậu',
          'Rau lá xanh đậm',
          'Ngũ cốc tăng cường sắt',
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      NutritionModel(
        id: const Uuid().v4(),
        title: 'Canxi cho xương và răng',
        category: 'Tam cá nguyệt 3',
        description:
            'Canxi góp phần hỗ trợ xương và răng của bé, đồng thời hỗ trợ hoạt động cơ và thần kinh của mẹ.',
        benefits: [
          'Hỗ trợ xương và răng của bé',
          'Góp phần duy trì sức khỏe xương của mẹ',
          'Hỗ trợ hoạt động cơ',
          'Góp phần hỗ trợ huyết áp ổn định',
        ],
        recommendedFoods: [
          'Sữa và sản phẩm từ sữa',
          'Sữa thực vật tăng cường canxi',
          'Đậu phụ',
          'Cá hồi có xương mềm',
          'Bông cải xanh và rau lá xanh',
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      NutritionModel(
        id: const Uuid().v4(),
        title: 'Đạm sau sinh',
        category: 'Sau sinh',
        description:
            'Sau sinh, thực phẩm giàu đạm có thể hỗ trợ phục hồi cơ thể và nhu cầu dinh dưỡng khi nuôi con bằng sữa mẹ.',
        benefits: [
          'Hỗ trợ phục hồi mô',
          'Góp phần đáp ứng nhu cầu dinh dưỡng sau sinh',
          'Hỗ trợ hệ miễn dịch',
          'Giúp bữa ăn no lâu hơn',
        ],
        recommendedFoods: [
          'Thịt nạc',
          'Cá',
          'Trứng',
          'Sữa và sản phẩm từ sữa',
          'Các loại hạt',
          'Các loại đậu',
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      NutritionModel(
        id: const Uuid().v4(),
        title: 'Thực phẩm nên tránh khi mang thai',
        category: 'Tam cá nguyệt 1',
        description:
            'Một số thực phẩm có thể làm tăng rủi ro nhiễm khuẩn hoặc chứa chất không phù hợp trong thai kỳ. Khi không chắc chắn, hãy hỏi nhân viên y tế.',
        benefits: [
          'Giảm nguy cơ bệnh lây qua thực phẩm',
          'Hạn chế tiếp xúc với chất có thể gây hại',
          'Giúp lựa chọn bữa ăn an toàn hơn',
        ],
        recommendedFoods: [],
        foodsToAvoid: [
          'Thịt sống hoặc chưa chín kỹ',
          'Trứng sống hoặc chưa chín kỹ',
          'Sữa chưa tiệt trùng',
          'Cá có hàm lượng thủy ngân cao',
          'Rau quả chưa rửa sạch',
          'Rượu bia',
          'Quá nhiều caffeine',
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }

  static List<RecipeModel> getRecipes() {
    return [
      RecipeModel(
        id: const Uuid().v4(),
        title: 'Trứng ốp cuộn cải bó xôi',
        category: 'Tam cá nguyệt 1',
        description:
            'Bữa sáng giàu đạm, có rau xanh và dễ chuẩn bị trong giai đoạn đầu thai kỳ.',
        ingredients: [
          '3 quả trứng',
          '1 chén cải bó xôi tươi',
          '50g phô mai feta hoặc phô mai phù hợp',
          '1 muỗng canh dầu ô liu',
          'Một ít muối và tiêu',
        ],
        steps: [
          'Đánh trứng với một ít muối và tiêu',
          'Làm nóng dầu ô liu trên chảo',
          'Cho cải bó xôi vào đảo đến khi mềm',
          'Đổ trứng đã đánh vào chảo',
          'Rắc phô mai lên trên',
          'Nấu đến khi trứng chín rồi gập đôi',
          'Dùng khi còn ấm',
        ],
        preparationTime: 5,
        cookingTime: 10,
        servings: 1,
        nutritionBenefits: [
          'Giàu đạm',
          'Có rau lá xanh',
          'Cung cấp canxi nếu dùng phô mai phù hợp',
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      RecipeModel(
        id: const Uuid().v4(),
        title: 'Súp đậu lăng và rau củ',
        category: 'Tam cá nguyệt 2',
        description:
            'Món súp giàu chất xơ, có đậu và rau củ, phù hợp cho bữa ăn nhẹ nhàng.',
        ingredients: [
          '1 chén đậu lăng đỏ',
          '2 củ cà rốt thái hạt lựu',
          '2 nhánh cần tây cắt nhỏ',
          '1 củ hành tây thái hạt lựu',
          '3 tép tỏi băm',
          '4 chén nước dùng rau củ',
          '1 lon cà chua cắt hạt lựu',
          '1 muỗng cà phê thì là',
          'Muối và tiêu vừa ăn',
        ],
        steps: [
          'Phi hành tây và tỏi đến khi thơm',
          'Cho cà rốt và cần tây vào nấu khoảng 5 phút',
          'Thêm đậu lăng, nước dùng, cà chua và thì là',
          'Đun sôi rồi hạ nhỏ lửa trong 25-30 phút',
          'Nêm vừa ăn',
          'Dùng nóng với bánh mì nguyên cám nếu thích',
        ],
        preparationTime: 10,
        cookingTime: 35,
        servings: 4,
        nutritionBenefits: [
          'Có nguồn sắt thực vật',
          'Giàu chất xơ',
          'Có nhiều rau củ',
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      RecipeModel(
        id: const Uuid().v4(),
        title: 'Cá hồi nướng rau củ',
        category: 'Tam cá nguyệt 3',
        description:
            'Bữa ăn có đạm, rau củ và chất béo tốt. Hãy chọn loại cá phù hợp cho thai kỳ.',
        ingredients: [
          '2 miếng cá hồi',
          '2 chén bông cải xanh',
          '1 chén cà chua bi',
          '2 muỗng canh dầu ô liu',
          '1 quả chanh',
          'Thì là tươi',
          'Muối và tiêu',
        ],
        steps: [
          'Làm nóng lò ở 200°C',
          'Đặt cá hồi và rau củ lên khay nướng',
          'Rưới dầu ô liu, nêm muối và tiêu',
          'Vắt nước chanh lên cá',
          'Nướng 15-20 phút đến khi cá chín',
          'Rắc thì là tươi',
          'Dùng ngay khi còn nóng',
        ],
        preparationTime: 10,
        cookingTime: 20,
        servings: 2,
        nutritionBenefits: [
          'Có omega-3',
          'Giàu đạm',
          'Có rau xanh',
          'Có vitamin D tự nhiên',
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      RecipeModel(
        id: const Uuid().v4(),
        title: 'Sinh tố tô sau sinh',
        category: 'Sau sinh',
        description:
            'Món sinh tố tô giàu năng lượng, phù hợp cho bữa phụ sau sinh.',
        ingredients: [
          '1 quả chuối',
          '1 chén quả mọng đông lạnh',
          '1/2 chén yến mạch',
          '1 muỗng canh hạt lanh',
          '1 chén sữa hạnh nhân hoặc sữa phù hợp',
          '1 muỗng canh bơ hạnh nhân',
          'Topping: granola, quả mọng, các loại hạt',
        ],
        steps: [
          'Xay chuối, quả mọng, yến mạch, hạt lanh, sữa và bơ hạnh nhân',
          'Đổ ra tô',
          'Thêm granola, quả mọng tươi và các loại hạt',
          'Dùng ngay',
        ],
        preparationTime: 5,
        cookingTime: 0,
        servings: 1,
        nutritionBenefits: [
          'Cung cấp năng lượng',
          'Giàu chất xơ',
          'Có chất béo tốt',
          'Dễ chuẩn bị',
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      RecipeModel(
        id: const Uuid().v4(),
        title: 'Tô quinoa đậu gà',
        category: 'Tam cá nguyệt 2',
        description:
            'Bữa ăn có ngũ cốc, đậu, rau xanh và chất béo tốt trong cùng một tô.',
        ingredients: [
          '1 chén quinoa',
          '1 lon đậu gà đã nướng',
          '1 quả bơ cắt lát',
          '1 chén cải kale bóp mềm',
          '1/2 chén cà chua bi',
          '2 muỗng canh sốt tahini',
          '1 quả chanh',
          'Dầu ô liu, muối, tiêu',
        ],
        steps: [
          'Nấu quinoa theo hướng dẫn trên bao bì',
          'Nướng đậu gà với dầu ô liu và gia vị ở 200°C trong 20 phút',
          'Bóp cải kale với nước chanh và dầu ô liu',
          'Xếp quinoa, đậu gà, cải kale, cà chua và bơ vào tô',
          'Rưới sốt tahini',
          'Nêm lại và dùng',
        ],
        preparationTime: 15,
        cookingTime: 25,
        servings: 2,
        nutritionBenefits: [
          'Có đạm thực vật',
          'Giàu chất xơ',
          'Có chất béo tốt',
          'Có nhiều rau củ',
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }
}
