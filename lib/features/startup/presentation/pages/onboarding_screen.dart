import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // <-- استيراد حزمة التوجيه

// نموذج يمثل بيانات كل صفحة
class OnboardingContent {
  final String image;
  final String title;
  final String description;
  final IconData icon;

  OnboardingContent({
    required this.image,
    required this.title,
    required this.description,
    required this.icon,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int currentIndex = 0;
  late PageController _controller;

  // قم بتعديل مسارات الصور لتتطابق مع مجلد assets الخاص بك
  final List<OnboardingContent> contents = [
    OnboardingContent(
      image: 'assets/images/coffee.png', // مسار صورة القهوة
      title: 'Fast Delivery',
      description:
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna.',
      icon: Icons.delivery_dining,
    ),
    OnboardingContent(
      image: 'assets/images/icecream.png', // مسار صورة الآيسكريم
      title: 'Easy Payment',
      description:
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna.',
      icon: Icons.credit_card,
    ),
    OnboardingContent(
      image: 'assets/images/pizza.png', // مسار صورة البيتزا
      title: 'Order For Food',
      description:
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna.',
      icon: Icons.receipt_long,
    ),
  ];

  @override
  void initState() {
    _controller = PageController(initialPage: 0);
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: contents.length,
            onPageChanged: (int index) {
              setState(() {
                currentIndex = index;
              });
            },
            itemBuilder: (_, i) {
              return Column(
                children: [
                  // النصف العلوي (الصورة)
                  Expanded(
                    flex: 5,
                    child: Image.asset(
                      contents[i].image,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                  // النصف السفلي (المعلومات)
                  Expanded(
                    flex: 5,
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/images/group.jpg'),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              contents[i].icon,
                              size: 40,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              contents[i].title,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 15),
                            Text(
                              contents[i].description,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                                height: 1.5,
                              ),
                            ),
                            const Spacer(),
                            // النقاط السفلية (Indicators)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                contents.length,
                                (index) => buildDot(index, context),
                              ),
                            ),
                            const SizedBox(height: 30),
                            // الزر السفلي
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: () {
                                  if (currentIndex == contents.length - 1) {
                                    // --- التعديل هنا: الانتقال باستخدام go_router ---
                                    context.go('/location-access');
                                  } else {
                                    _controller.nextPage(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      curve: Curves.easeIn,
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white.withOpacity(
                                    0.1,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  side: BorderSide(
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  currentIndex == contents.length - 1
                                      ? "Get Started"
                                      : "Next",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // زر التخطي (Skip)
          Positioned(
            top: 50,
            right: 20,
            child: TextButton(
              onPressed: () {
                // --- التعديل هنا: الانتقال مباشرة باستخدام go_router ---
                context.go('/location-access');
              },
              child: const Row(
                children: [
                  Text(
                    "Skip",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ودجت لرسم نقاط المؤشر (Dots)
  Container buildDot(int index, BuildContext context) {
    return Container(
      height: 4,
      width: currentIndex == index ? 20 : 10,
      margin: const EdgeInsets.only(right: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: currentIndex == index ? Colors.white : Colors.white38,
      ),
    );
  }
}