import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'sequential_quiz_screen.dart';
import 'multiplayer_setup_screen.dart'; // Import the new setup screen

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  late AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initializeAudio();
  }

  Future<void> _initializeAudio() async {
    try {
      await _audioPlayer.setVolume(0.1);
      await _audioPlayer.play(AssetSource('audios/audio1.mp3'));
    } catch (e) {
      debugPrint('Error initializing audio: $e');
    }
  }

  // Choose between Solo and Multiplayer
  void _showInitialChoice(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A237E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'اختر نظام اللعب',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 25),
            _buildMainOption(
              context: context,
              title: 'لعب فردي',
              subtitle: 'العب بمفردك في أوضاع مختلفة',
              icon: Icons.person,
              onTap: () {
                Navigator.pop(context);
                _showSoloMenu(context);
              },
            ),
            const SizedBox(height: 15),
            _buildMainOption(
              context: context,
              title: 'لعب جماعي',
              subtitle: 'تحدى أصدقائك في غرفة خاصة',
              icon: Icons.groups,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MultiplayerSetupScreen()),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // The Solo Menu (Your previous main menu)
  void _showSoloMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A237E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'اختر القسم الفردي',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 25),
            _buildMainOption(
              context: context,
              title: 'العباقرة',
              subtitle: 'اسئلة من برنامج العباقرة',
              icon: Icons.psychology,
              onTap: () {
                Navigator.pop(context);
                _showAbakeraModes(context);
              },
            ),
            const SizedBox(height: 15),
            _buildMainOption(
              context: context,
              title: 'كازينو الألعاب',
              subtitle: 'اسئلة من برنامج كازينو الألعاب',
              icon: Icons.casino,
              onTap: () {
                Navigator.pop(context);
                _audioPlayer.stop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const SequentialQuizScreen(isCasinoMode: true)),
                );
              },
            ),
            const SizedBox(height: 15),
            _buildMainOption(
              context: context,
              title: 'صباحو تحدي',
              subtitle: 'اسئلة من برنامج صباحو تحدي',
              icon: Icons.wb_sunny,
              onTap: () {
                Navigator.pop(context);
                _audioPlayer.stop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const SequentialQuizScreen(isSabahoMode: true)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAbakeraModes(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D47A1),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'العباقرة: اختر نظام اللعب',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 25),
            _buildModeOption(
              context: context,
              title: 'الوضع الكلاسيكي',
              subtitle: 'مراحل شاملة (علم، معرفة، فنون، عجلة الحظ)',
              icon: Icons.emoji_events,
              isCustom: false,
            ),
            const SizedBox(height: 15),
            _buildModeOption(
              context: context,
              title: 'وضع التخصص',
              subtitle: 'اختر مواضيع محددة لـ 16 سؤال مخصص',
              icon: Icons.settings_suggest,
              isCustom: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      color: Colors.white.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: CircleAvatar(backgroundColor: Colors.amber, child: Icon(icon, color: Colors.black)),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        onTap: onTap,
      ),
    );
  }

  Widget _buildModeOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isCustom,
  }) {
    return Card(
      color: Colors.white.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: CircleAvatar(backgroundColor: Colors.orange, child: Icon(icon, color: Colors.white)),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        onTap: () {
          Navigator.pop(context);
          _audioPlayer.stop();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => SequentialQuizScreen(isCustomMode: isCustom)),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFF1A237E), Color(0xFF0A0F2D)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'عبقرينو',
                style: TextStyle(fontSize: 60, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2),
              ),
              const SizedBox(height: 10),
              const Text('اختبار المعلومات والذكاء', style: TextStyle(fontSize: 22, color: Colors.white70)),
              const SizedBox(height: 60),
              ElevatedButton(
                onPressed: () => _showInitialChoice(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
                  elevation: 10,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(35)),
                ),
                child: const Text('ابدأ اللعب', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}