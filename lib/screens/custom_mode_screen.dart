import 'package:flutter/material.dart';
import 'package:appqreno/models/models.dart';
import 'package:appqreno/models/question_data.dart';
import 'question_screen.dart';
import 'final_results_screen.dart';

class CustomModeScreen extends StatefulWidget {
  final Map<String, List<Question>> allQuestionsByCategory;

  const CustomModeScreen({super.key, required this.allQuestionsByCategory});

  @override
  State<CustomModeScreen> createState() => _CustomModeScreenState();
}

class _CustomModeScreenState extends State<CustomModeScreen> {
  final List<String> availableSubcategories = [
    'جغرافيا', 'تاريخ', 'أدب', 'علوم', 
    'معلومات عامة', 'رياضة', 'تكنولوجيا', 'قدرات ذهنية',
    'سينما و مسرح', 'اغاني و موسيقى', 'لوحات و معالم', 'سرعة البديهة'
  ];

  final List<String> _selectedSubcategories = [];

  void _toggleCategory(String category) {
    setState(() {
      if (_selectedSubcategories.contains(category)) {
        _selectedSubcategories.remove(category);
      } else {
        _selectedSubcategories.add(category);
      }
    });
  }

  void _startCustomQuiz() {
    // Generate exactly 16 questions based on selection
    final customQuestions = QuestionData.getCustomQuestions(
      _selectedSubcategories,
      widget.allQuestionsByCategory,
      16,
    );

    final customCategory = Category(
      name: 'اختبار مخصص',
      color: Colors.orange,
      icon: Icons.settings_suggest,
      description: _selectedSubcategories.join('، '),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuestionScreen(
          category: customCategory,
          allQuestionsByCategory: widget.allQuestionsByCategory,
          onCompleted: (score) {
            // After 16 questions, go straight to results
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => FinalResultsScreen(
                  totalScore: score,
                  categoryScores: [score], // Custom mode treats all as one block
                  categories: [customCategory],
                ),
              ),
            );
          },
          customQuestions: customQuestions, // Pass pre-selected list
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F2D),
      appBar: AppBar(
        title: const Text('اختر مواضيعك'),
        backgroundColor: Colors.orange,
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Text(
              'اختر الأقسام التي تريدها في اختبارك (16 سؤال)',
              style: TextStyle(color: Colors.white, fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(15),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: availableSubcategories.length,
              itemBuilder: (context, index) {
                final category = availableSubcategories[index];
                final isSelected = _selectedSubcategories.contains(category);
                return GestureDetector(
                  onTap: () => _toggleCategory(category),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.orange : const Color(0xFF1A237E),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orange),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      category,
                      style: TextStyle(
                        color: isSelected ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(30.0),
            child: ElevatedButton(
              onPressed: _selectedSubcategories.isEmpty ? null : _startCustomQuiz,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('ابدأ الاختبار الآن', style: TextStyle(color: Colors.black)),
            ),
          ),
        ],
      ),
    );
  }
}