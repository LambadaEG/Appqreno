import 'package:flutter/material.dart';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'question_screen.dart';
import 'package:appqreno/models/models.dart';

class LuckyWheelScreen extends StatefulWidget {
  final Map<String, List<Question>> allQuestionsByCategory;
  final Function(int) onCompleted;

  const LuckyWheelScreen({
    super.key,
    required this.allQuestionsByCategory,
    required this.onCompleted,
  });

  @override
  State<LuckyWheelScreen> createState() => _LuckyWheelScreenState();
}

class _LuckyWheelScreenState extends State<LuckyWheelScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _angle = 0.0;
  bool _isSpinning = false;
  late AudioPlayer _audioPlayer;

  int _completedQuestions = 0;
  int _totalScore = 0;
  final int _totalQuestions = 4;

  final List<String> categories = [
    'أدب',
    'علوم',
    'معلومات عامة',
    'تاريخ',
    'جغرافيا',
    'رياضة',
    'تكنولوجيا',
    'قدرات ذهنية',
  ];

  final List<Color> colors = [
    const Color(0xFF3949AB), // Indigo
    const Color(0xFF1E88E5), // Blue
    const Color(0xFF3949AB),
    const Color(0xFF1E88E5),
    const Color(0xFF3949AB),
    const Color(0xFF1E88E5),
    const Color(0xFF3949AB),
    const Color(0xFF1E88E5),
  ];

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _controller = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.decelerate,
    );
  }

  void _spinWheel() async {
    if (_isSpinning) return;

    setState(() {
      _isSpinning = true;
    });

    await _playSpinAudio();

    final random = Random();
    final extraRotations = 6 + random.nextInt(4); // 6-10 full spins
    final segmentAngle = 2 * pi / categories.length;
    
    // Pick a winning index
    final winningIndex = random.nextInt(categories.length);
    
    final targetAngle = (extraRotations * 2 * pi) + 
                        (2 * pi - (winningIndex * segmentAngle)) - 
                        (segmentAngle / 2);

    _controller.reset();
    _controller.forward(from: 0).then((_) {
      _showWinningCategory(categories[winningIndex]);
    });

    _controller.addListener(() {
      setState(() {
        _angle = _animation.value * targetAngle;
      });
    });
  }

  Future<void> _playSpinAudio() async {
    try {
      await _audioPlayer.play(AssetSource('audios/wheel_spin.mp3'));
    } catch (e) {
      debugPrint("Spin audio error: $e");
    }
  }

  void _showWinningCategory(String category) {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1F3D),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.stars, color: Colors.amber, size: 50),
              const SizedBox(height: 15),
              Text(
                ':لقد وقع الاختيار على\n$category',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 10),
              Text(
                'السؤال رقم (${_completedQuestions + 1}/$_totalQuestions)',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                onPressed: () {
                  Navigator.pop(context);
                  _startQuestionForCategory(category);
                },
                child: const Text('ابدأ السؤال', style: TextStyle(color: Colors.black)),
              ),
            ),
          ],
        ),
      );
    });
  }

  void _startQuestionForCategory(String selectedCategory) {
    final tempCategory = Category(
      name: 'عجلة الحظ - $selectedCategory',
      color: const Color(0xFF42A5F5),
      icon: Icons.casino,
      description: 'سؤال في $selectedCategory',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuestionScreen(
          category: tempCategory,
          allQuestionsByCategory: widget.allQuestionsByCategory,
          onCompleted: _onQuestionCompleted,
          isSequential: true,
          selectedSubcategory: selectedCategory,
        ),
      ),
    );
  }

  void _onQuestionCompleted(int score) {
    if (!mounted) return;
    
    setState(() {
      _completedQuestions++;
      _totalScore += score;
      _isSpinning = false;
      _angle = 0.0;
      _controller.reset();
    });

    if (_completedQuestions >= _totalQuestions) {
      // Use Future.microtask to avoid navigation conflicts
      Future.microtask(() {
        if (mounted) {
          // Pop the wheel screen first
          Navigator.pop(context);
          // Then call onCompleted after a tiny delay
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              widget.onCompleted(_totalScore);
            }
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F2D),
      appBar: AppBar(
        title: Text('عجلة الحظ (${_completedQuestions + 1}/$_totalQuestions)'),
        backgroundColor: const Color(0xFF42A5F5),
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0xFF42A5F5).withOpacity(0.1), const Color(0xFF0A0F2D)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Stats Section
            Container(
              padding: const EdgeInsets.all(15),
              margin: const EdgeInsets.symmetric(horizontal: 30),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: _completedQuestions / _totalQuestions,
                    backgroundColor: Colors.white12,
                    color: Colors.amber,
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'النقاط المجمعة: $_totalScore',
                    style: const TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            
            const Spacer(),

            // The Wheel Stack
            Stack(
              alignment: Alignment.center,
              children: [
                // Glowing Background effect
                Container(
                  width: 310,
                  height: 310,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.2),
                        blurRadius: 50,
                        spreadRadius: 10,
                      )
                    ],
                  ),
                ),
                // The Rotating Wheel
                Transform.rotate(
                  angle: _angle - (pi / 2), // Start Index 0 at the top
                  child: SizedBox(
                    width: 300,
                    height: 300,
                    child: CustomPaint(
                      painter: WheelPainter(categories, colors),
                    ),
                  ),
                ),
                // Center Hub
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black26)],
                  ),
                  child: const Icon(Icons.casino, size: 35, color: Color(0xFF0A0F2D)),
                ),
                // Fixed Arrow Pointer at Top
                Positioned(
                  top: -15,
                  child: Column(
                    children: [
                      Icon(Icons.arrow_drop_down_sharp, size: 60, color: Colors.red[700]),
                    ],
                  ),
                ),
              ],
            ),

            const Spacer(),

            // Spin Button
            ElevatedButton(
              onPressed: _isSpinning ? null : _spinWheel,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                disabledBackgroundColor: Colors.grey,
                padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(35)),
                elevation: 10,
              ),
              child: Text(
                _isSpinning ? 'جاري الدوران...' : 'إضغط للتدوير',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class WheelPainter extends CustomPainter {
  final List<String> categories;
  final List<Color> colors;

  WheelPainter(this.categories, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final segmentAngle = 2 * pi / categories.length;

    final paint = Paint()..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 0; i < categories.length; i++) {
      paint.color = colors[i % colors.length];
      
      final startAngle = i * segmentAngle;

      // Draw segment
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segmentAngle,
        true,
        paint,
      );

      // Draw Divider Line
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segmentAngle,
        true,
        borderPaint,
      );

      // Draw Text
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(startAngle + segmentAngle / 2);
      
      final textPainter = TextPainter(
        text: TextSpan(
          text: categories[i],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(blurRadius: 2, color: Colors.black)],
          ),
        ),
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.center,
      )..layout();

      // Position text halfway along the radius
      textPainter.paint(canvas, Offset(radius * 0.45, -textPainter.height / 2));
      canvas.restore();
    }
    
    // Outer Border Circle
    canvas.drawCircle(center, radius, borderPaint..strokeWidth = 4..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}