import 'package:flutter/material.dart';
import 'start_screen.dart';
import 'package:appqreno/models/models.dart';

class FinalResultsScreen extends StatelessWidget {
  final int totalScore;
  final List<int> categoryScores;
  final List<Category> categories;

  const FinalResultsScreen({
    super.key,
    required this.totalScore,
    required this.categoryScores,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    // Total questions is 16 for both Classic and Custom modes
    const int totalQuestions = 16;
    final percentage = (totalScore / totalQuestions) * 100;
    
    String message = '';
    Color messageColor = Colors.blue;

    if (percentage >= 90) {
      message = 'ممتاز! أنت عبقرية حقاً 🎉';
      messageColor = Colors.green;
    } else if (percentage >= 70) {
      message = 'جيد جداً! مستوى رائع 👍';
      messageColor = Colors.blue;
    } else if (percentage >= 50) {
      message = 'جيد! يمكنك التحسين 💪';
      messageColor = Colors.orange;
    } else {
      message = 'حاول مرة أخرى! لا تيأس 🌟';
      messageColor = Colors.red;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F2D),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Color(0xFF1A237E),
              Color(0xFF0A0F2D),
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.emoji_events,
                  size: 80,
                  color: Colors.amber,
                ),
                const SizedBox(height: 20),
                const Text(
                  'النتيجة النهائية',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '$totalScore / $totalQuestions',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 24,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: messageColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      // FIX: If there is only 1 category (Custom Mode), denominator is 16.
                      // If there are multiple (Classic Mode), each is 4.
                      int denominator = (categories.length == 1) ? 16 : 4;

                      return Card(
                        color: const Color(0xFF1A237E),
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        child: ListTile(
                          leading: Icon(
                            categories[index].icon,
                            color: categories[index].color,
                          ),
                          title: Text(
                            categories[index].name,
                            style: const TextStyle(color: Colors.white),
                          ),
                          trailing: Text(
                            '${categoryScores[index]}/$denominator',
                            style: TextStyle(
                              color: categories[index].color,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const StartScreen()),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    'العودة للرئيسية',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}