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
  final bool isCasinoMode;
  final bool isSabahoMode; // إضافة وضع صباحو تحدي

  const SequentialQuizScreen({
    super.key,
    this.isCustomMode = false,
    this.isCasinoMode = false,
    this.isSabahoMode = false, // القيمة الافتراضية false
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

        // ترتيب التحقق من الأوضاع
        if (widget.isSabahoMode) {
          _startSabahoDirectly();
        } else if (widget.isCasinoMode) {
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

  // دالة لبدء وضع صباحو تحدي مباشرة
  void _startSabahoDirectly() {
    final sabahoQuestions = QuestionData.getCustomQuestions(
      ['صباحو'], // يجب أن يطابق الاسم في الـ Spreadsheet
      allQuestionsByCategory,
      16,
    );

    final sabahoCategory = Category(
      name: 'صباحو تحدي',
      color: Colors.orange,
      icon: Icons.wb_sunny,
      description: 'تحدي الـ 16 سؤال الصباحي',
    );

    _navigateToQuestionScreen(sabahoCategory, sabahoQuestions);
  }

  void _startCasinoDirectly() {
    final casinoQuestions = QuestionData.getCustomQuestions(
      ['كازينو'],
      allQuestionsByCategory,
      16,
    );

    final casinoCategory = Category(
      name: 'كازينو الألعاب',
      color: Colors.purple,
      icon: Icons.casino,
      description: 'تحدي الـ 16 سؤال',
    );

    _navigateToQuestionScreen(casinoCategory, casinoQuestions);
  }

  // دالة موحدة للانتقال لشاشة الأسئلة في الأوضاع المباشرة
  void _navigateToQuestionScreen(Category cat, List<Question> qs) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => QuestionScreen(
          category: cat,
          allQuestionsByCategory: allQuestionsByCategory,
          customQuestions: qs,
          onCompleted: (score) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => FinalResultsScreen(
                  totalScore: score,
                  categoryScores: [score],
                  categories: [cat],
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
        : (widget.isSabahoMode ? 'جاري تحضير تحدي صباحو...' : (widget.isCasinoMode ? 'جاري تحضير الكازينو...' : 'جاري التحميل...'));

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