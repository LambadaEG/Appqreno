import 'package:flutter/material.dart';
import 'dart:async';
import 'question_screen.dart';
import 'final_results_screen.dart';
import 'custom_mode_screen.dart'; 
import 'package:appqreno/models/models.dart';
import 'package:appqreno/models/question_data.dart';
import 'lucky_wheel_screen.dart';

class SequentialQuizScreen extends StatefulWidget {
  final bool isCustomMode;
  final bool isCasinoMode; // المتغير الذي يحدد هل نحن في وضع الكازينو

  const SequentialQuizScreen({
    super.key,
    this.isCustomMode = false,
    this.isCasinoMode = false,
  });

  @override
  State<SequentialQuizScreen> createState() => _SequentialQuizScreenState();
}

class _SequentialQuizScreenState extends State<SequentialQuizScreen> {
  final List<Category> categories = const [
    Category(
      name: 'العلم',
      color: Color(0xFF1565C0),
      icon: Icons.science,
      description: 'جغرافيا، تاريخ، أدب، علوم',
    ),
    Category(
      name: 'المعرفة',
      color: Color(0xFF1976D2),
      icon: Icons.lightbulb,
      description: 'معلومات عامة، رياضة، تكنولوجيا، قدرات ذهنية',
    ),
    Category(
      name: 'الفنون',
      color: Color(0xFF1E88E5),
      icon: Icons.palette,
      description: 'سينما ومسرح، أغاني وموسيقى، لوحات ومعالم، سرعة البديهة',
    ),
    Category(
      name: 'عجلة الحظ',
      color: Color(0xFF42A5F5),
      icon: Icons.casino,
      description: 'اختر موضوع عشوائي من مجموعة متنوعة',
    ),
  ];

  int currentCategoryIndex = 0;
  int totalScore = 0;
  List<int> categoryScores = [];
  bool isLoading = true;
  Map<String, List<Question>> allQuestionsByCategory = {};

  @override
  void initState() {
    super.initState();
    _initializeQuiz();
  }

  void _initializeQuiz() async {
    try {
      allQuestionsByCategory = await QuestionData.loadQuestionsFromSheet();
      
      if (mounted) {
        setState(() {
          isLoading = false;
        });

        // التعديل هنا: إذا كان وضع كازينو، ابدأ الأسئلة فوراً ولا تذهب لشاشة الاختيار
        if (widget.isCasinoMode) {
          _startCasinoDirectly();
        } else if (widget.isCustomMode) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CustomModeScreen(
                allQuestionsByCategory: allQuestionsByCategory,
              ),
            ),
          );
        } else {
          _startNextCategory();
        }
      }
    } catch (e) {
      debugPrint('Error loading questions: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        _showErrorDialog();
      }
    }
  }

  // هذه الدالة تقوم بسحب أسئلة الكازينو وبدء الشاشة فوراً
  void _startCasinoDirectly() {
    final casinoQuestions = QuestionData.getCustomQuestions(
      ['كازينو'], // يجب أن يكون هذا الاسم مطابقاً تماماً لما هو مكتوب في الـ Spreadsheet
      allQuestionsByCategory,
      16,
    );

    final casinoCategory = Category(
      name: 'كازينو الألعاب',
      color: Colors.purple,
      icon: Icons.casino,
      description: 'تحدي الـ 16 سؤال',
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => QuestionScreen(
          category: casinoCategory,
          allQuestionsByCategory: allQuestionsByCategory,
          customQuestions: casinoQuestions,
          onCompleted: (score) {
            // عند الانتهاء من الكازينو، اذهب لصفحة النتائج النهائية مباشرة
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => FinalResultsScreen(
                  totalScore: score,
                  categoryScores: [score],
                  categories: [casinoCategory],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('خطأ في التحميل'),
        content: const Text('تعذر تحميل الأسئلة. تأكد من اتصال الإنترنت.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  void _startNextCategory() {
    if (currentCategoryIndex < categories.length && mounted) {
      final currentCategory = categories[currentCategoryIndex];
      
      if (currentCategory.name == 'عجلة الحظ') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LuckyWheelScreen(
              allQuestionsByCategory: allQuestionsByCategory,
              onCompleted: onCategoryCompleted,
            ),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuestionScreen(
              category: currentCategory,
              allQuestionsByCategory: allQuestionsByCategory,
              onCompleted: onCategoryCompleted,
              isSequential: true,
            ),
          ),
        );
      }
    }
  }

  void onCategoryCompleted(int score) {
    if (!mounted) return;
    setState(() {
      categoryScores.add(score);
      totalScore += score;
      currentCategoryIndex++;
    });

    if (currentCategoryIndex < categories.length) {
      Future.delayed(const Duration(seconds: 1), () => _startNextCategory());
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => FinalResultsScreen(
            totalScore: totalScore,
            categoryScores: categoryScores,
            categories: categories,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String loadingMessage = isLoading 
        ? 'جاري تحميل الأسئلة...' 
        : (widget.isCasinoMode 
            ? 'جاري تحضير الكازينو...' 
            : 'جاري التحميل...');

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F2D),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.amber),
            const SizedBox(height: 20),
            Text(loadingMessage, style: const TextStyle(fontSize: 20, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}