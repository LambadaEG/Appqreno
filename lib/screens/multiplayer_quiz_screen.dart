import 'package:flutter/material.dart';
import 'package:appqreno/models/models.dart';
import 'question_screen.dart';
import 'final_results_screen.dart';

class MultiplayerQuizScreen extends StatelessWidget {
  final List<Question> questions;
  final String roomCode;
  final String userName;
  final String mode;

  const MultiplayerQuizScreen({
    super.key,
    required this.questions,
    required this.roomCode,
    required this.userName,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    final multiplayerCategory = Category(
      name: mode == 'Casino' ? 'كازينو الألعاب' : (mode == 'Sabaho' ? 'صباحو تحدي' : 'العباقرة'),
      color: Colors.indigo,
      icon: Icons.groups,
      description: 'تحدي جماعي مباشر',
    );

    return QuestionScreen(
      category: multiplayerCategory,
      allQuestionsByCategory: const {}, // Questions already provided
      customQuestions: questions,
      onCompleted: (score) {
        // Here you will later add the Firebase score sync logic
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => FinalResultsScreen(
              totalScore: score,
              categoryScores: [score],
              categories: [multiplayerCategory],
            ),
          ),
        );
      },
    );
  }
}