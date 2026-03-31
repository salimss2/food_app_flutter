import 'dart:convert';
import 'dart:io';
import 'dart:math';

void main() {
  final random = Random();

  // قوائم الأسماء لتوليد بيانات واقعية
  final restaurantPrefixes = [
    'مطعم',
    'مطبخ',
    'بوفية',
    'كافيه',
    'بيت',
    'ركن',
    'ملك',
    'مشويات',
  ];
  final restaurantNames = [
    'المكلا',
    'حضرموت',
    'الستين',
    'الخور',
    'الضيافة',
    'السعادة',
    'الشاطئ',
    'الشرج',
    'فوه',
    'المضغوط',
    'الجزيرة',
  ];

  final mealCategories = [
    'شعبي',
    'مشويات',
    'وجبات سريعة',
    'بيتزا',
    'مشروبات',
    'حلى',
  ];
  final popularMeals = [
    'مضغوط دجاج',
    'مندي لحم',
    'مظبي دجاج',
    'عقدة دجاج',
    'عقدة لحم',
    'برجر لحم دبل',
    'برجر دجاج مقرمش',
    'بيتزا مارغريتا',
    'بيتزا بيبروني',
    'شاورما عربي',
    'صاروخ شاورما',
    'بروستد عادي',
    'بروستد حراق',
    'عصير مانجو طازج',
    'عصير ليمون نعناع',
    'موهيتو',
    'كنافة',
    'معصوب',
  ];

  final mealImages = [
    'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=500&q=80', // Pizza
    'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=500&q=80', // Burger
    'https://images.unsplash.com/photo-1619881589316-56c7f9e6b587?w=500&q=80', // Rice/Meat
    'https://images.unsplash.com/photo-1628840042765-356cda07504e?w=500&q=80', // Fries/Fastfood
    'https://images.unsplash.com/photo-1528605248644-14dd04022da1?w=500&q=80', // Shawarma
  ];

  List<Map<String, dynamic>> restaurants = [];

  // توليد 50 مطعم
  for (int i = 1; i <= 50; i++) {
    String resName =
        '${restaurantPrefixes[random.nextInt(restaurantPrefixes.length)]} ${restaurantNames[random.nextInt(restaurantNames.length)]}';

    List<Map<String, dynamic>> meals = [];

    // توليد 50 وجبة لكل مطعم
    for (int j = 1; j <= 50; j++) {
      String mealName = popularMeals[random.nextInt(popularMeals.length)];
      meals.add({
        'id': 'meal_${i}_$j',
        'name': '$mealName ${j > 10 ? "مميز" : ""}'.trim(),
        'description':
            'وصف شهي ومميز لهذه الوجبة الرائعة المحضرة بأفضل المكونات الطازجة.',
        'price':
            (random.nextInt(40) * 100) + 1000, // أسعار بين 1000 و 5000 ريال
        'imageUrl': mealImages[random.nextInt(mealImages.length)],
        'category': mealCategories[random.nextInt(mealCategories.length)],
        'isAvailable': true,
      });
    }

    restaurants.add({
      'id': 'rest_$i',
      'name': resName,
      'description': 'أفضل المأكولات في المكلا، طعم لا ينسى وجودة عالية.',
      'rating': (random.nextDouble() * 2 + 3).toStringAsFixed(
        1,
      ), // تقييم بين 3.0 و 5.0
      'deliveryTime':
          '${random.nextInt(30) + 15} - ${random.nextInt(20) + 45} دقيقة',
      'deliveryFee': random.nextBool() ? 0 : 1000, // توصيل مجاني أو 1000 ريال
      'imageUrl': mealImages[random.nextInt(mealImages.length)], // صورة للمطعم
      'menu': meals, // إضافة الـ 50 وجبة داخل المطعم
    });
  }

  // إنشاء هيكل JSON النهائي
  Map<String, dynamic> finalDatabase = {'restaurants': restaurants};

  // حفظ البيانات في ملف JSON
  File file = File('mock_database.json');
  file.writeAsStringSync(jsonEncode(finalDatabase));

  print('✅ تم بنجاح! تم إنشاء 50 مطعم و 2500 وجبة في ملف mock_database.json');
}
