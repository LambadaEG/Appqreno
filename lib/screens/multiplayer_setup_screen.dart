import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'lobby_screen.dart';

class MultiplayerSetupScreen extends StatefulWidget {
  const MultiplayerSetupScreen({super.key});

  @override
  State<MultiplayerSetupScreen> createState() => _MultiplayerSetupScreenState();
}

class _MultiplayerSetupScreenState extends State<MultiplayerSetupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;

  String _generateRoomCode() => (1000 + Random().nextInt(9000)).toString();

  void _onCreateRoom() async {
    if (_nameController.text.trim().isEmpty) {
      _showError("من فضلك أدخل اسمك أولاً");
      return;
    }
    setState(() => _isLoading = true);
    String code = _generateRoomCode();
    try {
      await FirebaseFirestore.instance.collection('rooms').doc(code).set({
        'status': 'waiting',
        'mode': 'Classic',
        'hostName': _nameController.text.trim(),
        'players': [
          {'name': _nameController.text.trim(), 'isReady': false, 'score': 0, 'isHost': true}
        ],
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (context) => LobbyScreen(
          roomCode: code, userName: _nameController.text.trim(), isHost: true,
        )));
      }
    } catch (e) {
      _showError("فشل إنشاء الغرفة: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onJoinRoom() async {
    String name = _nameController.text.trim();
    String code = _codeController.text.trim();
    if (name.isEmpty || code.isEmpty) {
      _showError("أدخل الاسم وكود الغرفة");
      return;
    }
    setState(() => _isLoading = true);
    try {
      DocumentSnapshot roomDoc = await FirebaseFirestore.instance.collection('rooms').doc(code).get();
      if (!roomDoc.exists) {
        _showError("الغرفة غير موجودة!");
        return;
      }
      if (roomDoc.get('status') != 'waiting') {
        _showError("بدأت اللعبة بالفعل");
        return;
      }
      await FirebaseFirestore.instance.collection('rooms').doc(code).update({
        'players': FieldValue.arrayUnion([
          {'name': name, 'isReady': false, 'score': 0, 'isHost': false}
        ]),
      });
      if (mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (context) => LobbyScreen(
          roomCode: code, userName: name, isHost: false,
        )));
      }
    } catch (e) {
      _showError("خطأ في الانضمام: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F2D),
      appBar: AppBar(title: const Text('اللعب الجماعي'), backgroundColor: const Color(0xFF1A237E)),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(25.0),
            child: Column(
              children: [
                const Icon(Icons.group_add, size: 80, color: Colors.amber),
                const SizedBox(height: 40),
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('اسمك المستعار', Icons.person),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _isLoading ? null : _onCreateRoom,
                  style: _buttonStyle(Colors.green[700]!),
                  child: const Text('إنشاء غرفة جديدة', style: TextStyle(color: Colors.white, fontSize: 18)),
                ),
                const Divider(height: 60, color: Colors.white24),
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 8),
                  decoration: _inputDecoration('كود الغرفة', Icons.vpn_key),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _onJoinRoom,
                  style: _buttonStyle(Colors.blue[800]!),
                  child: const Text('انضمام للغرفة', style: TextStyle(color: Colors.white, fontSize: 18)),
                ),
              ],
            ),
          ),
          if (_isLoading) Container(color: Colors.black54, child: const Center(child: CircularProgressIndicator(color: Colors.amber))),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) => InputDecoration(
    labelText: label, labelStyle: const TextStyle(color: Colors.amber),
    prefixIcon: Icon(icon, color: Colors.amber),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.white24)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.amber)),
  );

  ButtonStyle _buttonStyle(Color color) => ElevatedButton.styleFrom(
    backgroundColor: color, padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
  );
}