import 'package:flutter/material.dart';
import 'dart:async';
import 'package:appqreno/models/models.dart';
import 'package:appqreno/models/question_data.dart';
import 'start_screen.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:math';

class QuestionScreen extends StatefulWidget {
  final Category category;
  final Map<String, List<Question>> allQuestionsByCategory;
  final Function(int) onCompleted;
  final bool isSequential;
  final String? selectedSubcategory;
  final List<Question>? customQuestions; // Added for Custom Mode

  const QuestionScreen({
    super.key,
    required this.category,
    required this.allQuestionsByCategory,
    required this.onCompleted,
    this.isSequential = false,
    this.selectedSubcategory,
    this.customQuestions, // Added for Custom Mode
  });

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> {
  int currentQuestionIndex = 0;
  int score = 0;
  int timeLeft = 20;
  late Timer _timer;
  List<int?> selectedAnswers = [];
  bool showAnswerFeedback = false;
  int? correctAnswerIndex;
  late List<Question> questions;
  bool _isInitialized = false;
  late AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    _initializeBasicState();
    _audioPlayer = AudioPlayer();
  }

  void _initializeBasicState() {
    selectedAnswers = [];
    showAnswerFeedback = false;
    correctAnswerIndex = null;
    currentQuestionIndex = 0;
    score = 0;
    timeLeft = 20;
    _isInitialized = false;
  }

  void _playQuestionAudio() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      await _audioPlayer.setVolume(0.1);
      await _audioPlayer.play(AssetSource('audios/audio2.mp3'));
    } catch (e) {
      debugPrint("Audio error: $e");
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _initializeQuestions();
    }
  }

  void _initializeQuestions() {
    try {
      // 1. Check if Custom Questions were passed (Custom Mode)
      if (widget.customQuestions != null && widget.customQuestions!.isNotEmpty) {
        questions = widget.customQuestions!;
        debugPrint('✅ Custom Mode - Total questions: ${questions.length}');
      } 
      // 2. Check if Lucky Wheel subcategory was passed
      else if (widget.selectedSubcategory != null) {
        final categoryQuestions = widget.allQuestionsByCategory[widget.selectedSubcategory!];
        
        if (categoryQuestions == null || categoryQuestions.isEmpty) {
          _handleInitError();
          return;
        }
        
        final random = Random();
        questions = [categoryQuestions[random.nextInt(categoryQuestions.length)]];
      } 
      // 3. Fallback to Normal Category Flow
      else {
        questions = QuestionData.getQuestionsForMainCategory(
          widget.category.name,
          widget.allQuestionsByCategory,
        );
      }

      if (questions.isEmpty) {
        _handleInitError();
        return;
      }

      // Finalize UI State
      selectedAnswers = List.filled(questions.length, null);
      _startTimer();
      _playQuestionAudio();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('❌ Error initializing questions: $e');
      _handleInitError();
    }
  }

  void _handleInitError() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showNotEnoughQuestionsError();
    });
  }

  void _showNotEnoughQuestionsError() {
    final errorCategory = widget.selectedSubcategory ?? widget.category.name;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('لا توجد أسئلة كافية'),
        content: Text('لا توجد أسئلة كافية في قاعدة البيانات للفئة $errorCategory.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (timeLeft > 0) {
            timeLeft--;
          } else {
            timer.cancel();
            if (!showAnswerFeedback) _handleTimeOut();
          }
        });
      }
    });
  }

  void _handleTimeOut() {
    if (currentQuestionIndex >= questions.length) return;
    final currentQuestion = questions[currentQuestionIndex];
    
    if (mounted) {
      setState(() {
        showAnswerFeedback = true;
        correctAnswerIndex = currentQuestion.correctAnswerIndex;
      });
    }

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _goToNextQuestion();
    });
  }

  void selectAnswer(int answerIndex) {
    if (currentQuestionIndex >= questions.length) return;
    if (selectedAnswers[currentQuestionIndex] == null && !showAnswerFeedback) {
      final currentQuestion = questions[currentQuestionIndex];
      
      if (mounted) {
        setState(() {
          selectedAnswers[currentQuestionIndex] = answerIndex;
          showAnswerFeedback = true;
          correctAnswerIndex = currentQuestion.correctAnswerIndex;
          
          if (answerIndex == currentQuestion.correctAnswerIndex) {
            score++;
          }
        });
      }

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) _goToNextQuestion();
      });
    }
  }

  void _goToNextQuestion() {
    if (!mounted) return;
    _timer.cancel();

    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        timeLeft = 20;
        showAnswerFeedback = false;
        correctAnswerIndex = null;
        _startTimer();
      });
      _playQuestionAudio();
    } else {
      if (widget.selectedSubcategory != null) {
        // For wheel questions: call onCompleted AND pop the question screen
        widget.onCompleted(score);
        Navigator.pop(context); // ← KEEP THIS UNCOMMENTED
      } else {
        // Normal or Custom mode (completes the sequence)
        widget.onCompleted(score);
      }
    }
  }
  Future<bool> _onWillPop() async {
    if (_timer.isActive) _timer.cancel();
    
    final bool? shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إنهاء الاختبار'),
        content: const Text(
          'هل تريد إنهاء الاختبار والعودة إلى الصفحة الرئيسية؟ سيتم فقدان تقدمك الحالي',
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('لا', style: TextStyle(color: Colors.blue)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const StartScreen()),
                (route) => false,
              );
            },
            child: const Text('نعم', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return shouldPop ?? false;
  }

  @override
  void dispose() {
    _timer.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (!_isInitialized || questions.isEmpty || currentQuestionIndex >= questions.length) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0F2D),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.amber),
              const SizedBox(height: 20),
              Text(
                !_isInitialized ? 'جاري تحميل الأسئلة...' : 'جاري الانتقال...',
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    final currentQuestion = questions[currentQuestionIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F2D),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.category.name),
            Text(currentQuestion.categoryType, style: const TextStyle(fontSize: 14)),
          ],
        ),
        backgroundColor: widget.category.color,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [widget.category.color.withOpacity(0.2), const Color(0xFF0A0F2D)],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'السؤال ${currentQuestionIndex + 1}/${questions.length}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: timeLeft <= 5 ? Colors.red : Colors.blue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$timeLeft ثانية',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Card(
                      color: const Color(0xFF1A237E),
                      elevation: 5,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Text(
                              currentQuestion.categoryType,
                              style: const TextStyle(fontSize: 18, color: Colors.amber, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              currentQuestion.text,
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1.5, color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ...currentQuestion.options.asMap().entries.map((entry) {
                      final index = entry.key;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: OptionButton(
                          text: entry.value,
                          isSelected: selectedAnswers[currentQuestionIndex] == index,
                          isCorrect: index == currentQuestion.correctAnswerIndex,
                          showCorrect: showAnswerFeedback && index == currentQuestion.correctAnswerIndex,
                          showWrong: showAnswerFeedback && selectedAnswers[currentQuestionIndex] == index && index != currentQuestion.correctAnswerIndex,
                          onTap: () => selectAnswer(index),
                          color: widget.category.color,
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OptionButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final bool isCorrect;
  final bool showCorrect;
  final bool showWrong;
  final VoidCallback onTap;
  final Color color;

  const OptionButton({
    super.key,
    required this.text,
    required this.isSelected,
    required this.isCorrect,
    required this.showCorrect,
    required this.showWrong,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor = const Color(0xFF1A237E);
    Color textColor = Colors.white;
    Color borderColor = Colors.blue;

    if (showWrong) {
      backgroundColor = Colors.red;
      borderColor = Colors.red;
    } else if (showCorrect) {
      backgroundColor = Colors.green;
      borderColor = Colors.green;
    } else if (isSelected) {
      backgroundColor = color;
      borderColor = color;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor, width: 2),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 3)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                text,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: textColor),
                textAlign: TextAlign.center,
              ),
            ),
            if (showCorrect) const Icon(Icons.check_circle, color: Colors.white, size: 20),
            if (showWrong) const Icon(Icons.cancel, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}