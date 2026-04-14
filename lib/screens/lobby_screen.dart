import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'multiplayer_quiz_screen.dart';
import 'package:appqreno/models/models.dart';
import 'package:appqreno/models/question_data.dart';

class LobbyScreen extends StatefulWidget {
  final String roomCode;
  final String userName;
  final bool isHost;

  const LobbyScreen({super.key, required this.roomCode, required this.userName, required this.isHost});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  String selectedMode = 'Classic';

  void _toggleReady(List players) async {
    int myIndex = players.indexWhere((p) => p['name'] == widget.userName);
    if (myIndex != -1) {
      players[myIndex]['isReady'] = !players[myIndex]['isReady'];
      await FirebaseFirestore.instance.collection('rooms').doc(widget.roomCode).update({'players': players});
    }
  }

  void _updateMode(String mode) async {
    setState(() => selectedMode = mode);
    await FirebaseFirestore.instance.collection('rooms').doc(widget.roomCode).update({'mode': mode});
  }

  void _startGame() async {
    Map<String, List<Question>> allQuestions = await QuestionData.loadQuestionsFromSheet();
    List<Map<String, dynamic>> sharedQuestions = [];

    if (selectedMode == 'Classic') {
      final List<String> sequence = [
        'جغرافيا', 'تاريخ', 'أدب', 'علوم',
        'معلومات عامة', 'رياضة', 'تكنولوجيا', 'قدرات ذهنية',
        'سينما و مسرح', 'اغاني و موسيقى', 'لوحات و معالم', 'سرعة البديهة',
        'تاريخ', 'رياضة', 'تكنولوجيا', 'علوم' 
      ];

      for (var sub in sequence) {
        final qList = QuestionData.getCustomQuestions([sub], allQuestions, 1);
        if (qList.isNotEmpty) {
          sharedQuestions.add({
            'text': qList[0].text,
            'correctAnswer': qList[0].correctAnswer,
            'options': qList[0].options,
            'category': qList[0].category,
          });
        }
      }
    } else {
      List<String> subCats = [selectedMode == 'Casino' ? 'كازينو' : 'صباحو'];
      final questions = QuestionData.getCustomQuestions(subCats, allQuestions, 16);
      sharedQuestions = questions.map((q) => {
        'text': q.text,
        'correctAnswer': q.correctAnswer,
        'options': q.options,
        'category': q.category,
      }).toList();
    }

    await FirebaseFirestore.instance.collection('rooms').doc(widget.roomCode).update({
      'status': 'playing',
      'sharedQuestions': sharedQuestions,
    });
  }

  // Update your _navigateToGame function inside _LobbyScreenState
  void _navigateToGame(String mode, List<dynamic>? sharedQuestions) {
    if (sharedQuestions == null) return;

    List<Question> syncedQuestions = sharedQuestions.map((q) => Question(
      text: q['text'] as String,
      correctAnswer: q['correctAnswer'] as String,
      options: List<String>.from(q['options']),
      category: q['category'] as String,
    )).toList();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MultiplayerQuizScreen(
          questions: syncedQuestions,
          roomCode: widget.roomCode,
          userName: widget.userName,
          mode: mode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F2D),
      appBar: AppBar(title: Text('غرفة الانتظار: ${widget.roomCode}'), backgroundColor: const Color(0xFF1A237E), centerTitle: true),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('rooms').doc(widget.roomCode).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) return const Center(child: CircularProgressIndicator(color: Colors.amber));

          var roomData = snapshot.data!.data() as Map<String, dynamic>;
          List players = roomData['players'] as List;
          String status = roomData['status'] ?? 'waiting';

          if (status == 'playing') {
            var sharedQuestions = roomData['sharedQuestions'] as List<dynamic>?;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _navigateToGame(roomData['mode'] ?? 'Classic', sharedQuestions);
            });
          }

          bool allReady = players.length >= 2 && players.every((p) => p['isReady'] == true);

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const Text('اللاعبون في الغرفة', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    itemCount: players.length,
                    itemBuilder: (context, index) {
                      bool isMe = players[index]['name'] == widget.userName;
                      return Card(
                        color: Colors.white.withOpacity(0.05),
                        child: ListTile(
                          leading: Icon(Icons.person, color: players[index]['isHost'] ? Colors.amber : Colors.white),
                          title: Text(players[index]['name'] + (isMe ? " (أنت)" : ""), style: const TextStyle(color: Colors.white)),
                          trailing: Icon(players[index]['isReady'] ? Icons.check_circle : Icons.radio_button_unchecked, color: players[index]['isReady'] ? Colors.green : Colors.red),
                        ),
                      );
                    },
                  ),
                ),
                if (widget.isHost) ...[
                  const Text('اختر نظام التحدي:', style: TextStyle(color: Colors.amber)),
                  DropdownButton<String>(
                    value: roomData['mode'] ?? 'Classic',
                    dropdownColor: const Color(0xFF1A237E),
                    isExpanded: true,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                    items: ['Classic', 'Casino', 'Sabaho'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (val) => _updateMode(val!),
                  ),
                  const SizedBox(height: 20),
                ],
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _toggleReady(players),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, padding: const EdgeInsets.symmetric(vertical: 15)),
                        child: const Text('جاهز'),
                      ),
                    ),
                    if (widget.isHost) const SizedBox(width: 15),
                    if (widget.isHost)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: allReady ? _startGame : null,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, padding: const EdgeInsets.symmetric(vertical: 15)),
                          child: const Text('ابدأ اللعب', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}