import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'start_screen.dart';
import 'dart:async';

class MultiplayerResultsScreen extends StatefulWidget {
  final String roomCode;
  final String userName;

  const MultiplayerResultsScreen({
    super.key,
    required this.roomCode,
    required this.userName,
  });

  @override
  State<MultiplayerResultsScreen> createState() => _MultiplayerResultsScreenState();
}

class _MultiplayerResultsScreenState extends State<MultiplayerResultsScreen> {
  List<Map<String, dynamic>> _players = [];
  bool _isLoading = true;
  String _waitingMessage = 'في انتظار باقي اللاعبين...';
  late StreamSubscription<DocumentSnapshot<Map<String, dynamic>>> _roomSubscription;

  @override
  void initState() {
    super.initState();
    _listenForResults();
  }

  void _listenForResults() {
    // Listen to room changes in real-time
    _roomSubscription = FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomCode)
        .snapshots()
        .listen((DocumentSnapshot<Map<String, dynamic>> snapshot) {
      if (snapshot.exists) {
        final players = List<Map<String, dynamic>>.from(snapshot.data()?['players'] ?? []);
        
        // Check if all players have scores (score > 0 or all have finished)
        final allPlayersHaveScores = players.isNotEmpty && players.every((p) => p['score'] != null && p['score'] > 0);
        
        if (allPlayersHaveScores) {
          // All players finished - show results
          players.sort((a, b) => (b['score'] ?? 0).compareTo(a['score'] ?? 0));
          
          setState(() {
            _players = players;
            _isLoading = false;
          });
        } else {
          // Still waiting for some players
          final completedCount = players.where((p) => p['score'] != null && p['score'] > 0).length;
          final totalCount = players.length;
          
          setState(() {
            _waitingMessage = 'في انتظار باقي اللاعبين ($completedCount/$totalCount)...';
            _isLoading = true;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _roomSubscription.cancel();
    _deleteRoom();
    super.dispose();
  }

  void _deleteRoom() async {
    try {
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomCode)
          .delete();
      debugPrint('Room ${widget.roomCode} deleted successfully');
    } catch (e) {
      debugPrint('Error deleting room: $e');
    }
  }

  Widget _getMedalIcon(int index) {
    switch (index) {
      case 0:
        return const Icon(Icons.emoji_events, color: Colors.amber, size: 28);
      case 1:
        return const Icon(Icons.emoji_events, color: Colors.grey, size: 28);
      case 2:
        return const Icon(Icons.emoji_events, color: Color(0xFFCD7F32), size: 28);
      default:
        return Text(
          '${index + 1}',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
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
        child: SafeArea(
          child: _isLoading
              ? _buildWaitingScreen()
              : _buildResultsScreen(),
        ),
      ),
    );
  }

  Widget _buildWaitingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Colors.amber,
            strokeWidth: 3,
          ),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.symmetric(horizontal: 30),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.hourglass_empty,
                  size: 50,
                  color: Colors.amber,
                ),
                const SizedBox(height: 20),
                Text(
                  _waitingMessage,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  'سيتم عرض النتائج تلقائياً عند انتهاء جميع اللاعبين',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsScreen() {
    return Column(
      children: [
        const SizedBox(height: 20),
        // Header
        const Icon(
          Icons.emoji_events,
          size: 80,
          color: Colors.amber,
        ),
        const SizedBox(height: 10),
        const Text(
          'نتيجة المباراة',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'كود الغرفة: ${widget.roomCode}',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.amber,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 30),
        
        // Leaderboard Title
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              SizedBox(width: 60),
              Expanded(
                child: Text(
                  'اللاعب',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(
                width: 80,
                child: Text(
                  'النقاط',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 10),
        
        // Players List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _players.length,
            itemBuilder: (context, index) {
              final player = _players[index];
              final isMe = player['name'] == widget.userName;
              final score = player['score'] ?? 0;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: isMe
                      ? Colors.amber.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(15),
                  border: isMe
                      ? Border.all(color: Colors.amber, width: 2)
                      : null,
                ),
                child: ListTile(
                  leading: SizedBox(
                    width: 50,
                    child: Center(
                      child: _getMedalIcon(index),
                    ),
                  ),
                  title: Text(
                    player['name'],
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                      color: isMe ? Colors.amber : Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  trailing: Container(
                    width: 80,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$score',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Back to Home Button
        Padding(
          padding: const EdgeInsets.all(20),
          child: ElevatedButton(
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
              minimumSize: const Size(double.infinity, 50),
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
        ),
        
        const SizedBox(height: 20),
      ],
    );
  }
}