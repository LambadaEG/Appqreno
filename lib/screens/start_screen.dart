import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'sequential_quiz_screen.dart';

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

  // القائمة الرئيسية لاختيار نوع اللعبة (عباقرة، كازينو، صباحو)
  void _showMainMenu(BuildContext context) {
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
              'اختر القسم',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 25),
            _buildMainOption(
              context: context,
              title: 'العباقرة',
              subtitle: 'اختبارات ذكاء ومعلومات عامة',
              icon: Icons.psychology,
              onTap: () {
                Navigator.pop(context);
                _showAbakeraModes(context); // يفتح اختيارات كلاسيكي ومتخصص
              },
            ),
            const SizedBox(height: 15),
            _buildMainOption(
              context: context,
              title: 'كازينو الألعاب',
              subtitle: 'قريباً...',
              icon: Icons.casino,
              isComingSoon: true,
              onTap: () {},
            ),
            const SizedBox(height: 15),
            _buildMainOption(
              context: context,
              title: 'صباحو تحدي',
              subtitle: 'قريباً...',
              icon: Icons.wb_sunny,
              isComingSoon: true,
              onTap: () {},
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // قائمة فرعية تظهر فقط عند اختيار "العباقرة"
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
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
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
            const SizedBox(height: 20),
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
    bool isComingSoon = false,
  }) {
    return Card(
      color: isComingSoon ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: CircleAvatar(
          backgroundColor: isComingSoon ? Colors.grey : Colors.amber,
          child: Icon(icon, color: Colors.black),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isComingSoon ? Colors.white54 : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isComingSoon ? Colors.white38 : Colors.white70,
            fontSize: 13,
          ),
        ),
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
        leading: CircleAvatar(
          backgroundColor: Colors.orange,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        onTap: () {
          Navigator.pop(context); // إغلاق القائمة
          _audioPlayer.stop(); // إيقاف الموسيقى
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => SequentialQuizScreen(isCustomMode: isCustom),
            ),
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
            colors: [
              Color(0xFF1A237E),
              Color(0xFF0A0F2D),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'عبقرينو',
                style: TextStyle(
                  fontSize: 60,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'اختبار المعلومات والذكاء',
                style: TextStyle(
                  fontSize: 22,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 60),
              ElevatedButton(
                onPressed: () => _showMainMenu(context), // يبدأ بالقائمة الرئيسية
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
                  elevation: 10,
                  shadowColor: Colors.amber.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(35),
                  ),
                ),
                child: const Text(
                  'ابدأ اللعب',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}