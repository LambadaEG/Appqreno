import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:appqreno/models/models.dart';
import 'question_screen.dart';
import 'multiplayer_results_screen.dart';

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

  Future<void> _saveScore(int score) async {
    try {
      final roomRef = FirebaseFirestore.instance.collection('rooms').doc(roomCode);
      final roomDoc = await roomRef.get();
      
      if (roomDoc.exists) {
        final players = List<Map<String, dynamic>>.from(roomDoc['players'] ?? []);
        final playerIndex = players.indexWhere((p) => p['name'] == userName);
        
        if (playerIndex != -1) {
          // Save the score (even 0 is valid)
          players[playerIndex]['score'] = score;
          await roomRef.update({'players': players});
          debugPrint('Score saved for $userName: $score');
        }
      }
    } catch (e) {
      debugPrint('Error saving score: $e');
    }
  }

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
      allQuestionsByCategory: const {},
      customQuestions: questions,
      onCompleted: (score) async {
        // Save the player's score to Firestore
        await _saveScore(score);
        
        // Navigate to the multiplayer results screen
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MultiplayerResultsScreen(
                roomCode: roomCode,
                userName: userName,
              ),
            ),
          );
        }
      },
    );
  }
}