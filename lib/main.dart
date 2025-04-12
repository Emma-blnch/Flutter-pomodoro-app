import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const PomodoroApp());
}

class PomodoroApp extends StatelessWidget {
  const PomodoroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pomodoro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Arial',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const PomodoroScreen(),
    );
  }
}

class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> with TickerProviderStateMixin {
  int workDuration = 2700; // 45 minutes en secondes
  int breakDuration = 900; // 15 minutes en secondes
  int totalRepetitions = 4;

  int currentSeconds = 2700;
  int currentRepetition = 0;
  bool isRunning = false;
  bool isWorking = true;
  Timer? timer;

  late final AnimationController _rippleController;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 13),
    )..repeat();
  }

  @override
  void dispose() {
    _rippleController.dispose();
    timer?.cancel();
    super.dispose();
  }

  void startTimer() {
    setState(() {
      isRunning = true;
      if (currentRepetition == 0) {
        currentRepetition = 1;
      }
    });

    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (currentSeconds > 0) {
        setState(() => currentSeconds--);
      } else {
        timer?.cancel();
        if (isWorking) {
          setState(() {
            isWorking = false;
            currentSeconds = breakDuration;
          });
          startTimer();
        } else {
          if (currentRepetition < totalRepetitions) {
            setState(() {
              isWorking = true;
              currentSeconds = workDuration;
              currentRepetition++;
            });
            startTimer();
          } else {
            resetTimer();
          }
        }
      }
    });
  }

   void toggleTimer() {
      setState(() {
        if (!isRunning) {
          isRunning = true;
          if (currentRepetition == 0) currentRepetition = 1;
          startTimer();
        } else {
          isRunning = false;
          timer?.cancel();
        }
      });
    }

  void resetTimer() {
    timer?.cancel();
    setState(() {
      isRunning = false;
      currentSeconds = workDuration;
      isWorking = true;
      currentRepetition = 0;
    });
  }

  String formatTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  double getProgress() {
    final total = isWorking ? workDuration : breakDuration;
    return 1 - (currentSeconds / total);
  }

  void openSettingsMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        int tempReps = totalRepetitions;
        int tempWork = workDuration ~/ 60;
        int tempBreak = breakDuration ~/ 60;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Réglages', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Répétitions'),
                      Text('$tempReps')
                    ],
                  ),
                  Slider(
                    min: 1,
                    max: 100,
                    divisions: 99,
                    value: tempReps.toDouble(),
                    onChanged: (value) => setModalState(() => tempReps = value.round()),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Travail (min)'),
                      Text('$tempWork')
                    ],
                  ),
                  Slider(
                    min: 1,
                    max: 60,
                    divisions: 59,
                    value: tempWork.toDouble(),
                    onChanged: (value) => setModalState(() => tempWork = value.round()),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Pause (min)'),
                      Text('$tempBreak')
                    ],
                  ),
                  Slider(
                    min: 1,
                    max: 60,
                    divisions: 59,
                    value: tempBreak.toDouble(),
                    onChanged: (value) => setModalState(() => tempBreak = value.round()),
                  ),

                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        totalRepetitions = tempReps;
                        workDuration = tempWork * 60;
                        breakDuration = tempBreak * 60;
                        if (!isRunning) currentSeconds = workDuration;
                      });
                      Navigator.pop(context);
                    },
                    child: const Text('Appliquer'),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final circleSize = size.width * 0.6;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              icon: const Icon(Icons.settings, size: 28),
              onPressed: openSettingsMenu,
              tooltip: 'Paramètres',
              color: Colors.black87,
            ),
          )
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/textures/otis-redding.png'),
            repeat: ImageRepeat.repeat,
            opacity: 0.1,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Opacity(
                opacity: currentRepetition > 0 ? 1 : 0,
                child: Text(
                  'RÉPÉTITION N°$currentRepetition',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              GestureDetector(
                onTap: toggleTimer,
                child: SizedBox(
                  width: circleSize * 2,
                  height: circleSize * 2,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (isRunning)
                        AnimatedBuilder(
                          animation: _rippleController,
                          builder: (context, child) {
                            final scale = 1 + _rippleController.value * 0.5;
                            final opacity = 1 - _rippleController.value;
                            return Container(
                              width: circleSize * scale,
                              height: circleSize * scale,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.lightBlueAccent.withOpacity(0.15 * opacity),
                              ),
                            );
                          },
                        ),
                      CustomPaint(
                        foregroundPainter: TimerPainter(progress: getProgress()),
                        child: Container(
                          width: circleSize,
                          height: circleSize,
                          decoration: const BoxDecoration(
                            color: Colors.lightBlueAccent,
                            shape: BoxShape.circle,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 28),
                              if (!isRunning && currentSeconds < workDuration)
                                const Icon(Icons.pause, size: 48)
                              else
                                Text(
                                  formatTime(currentSeconds),
                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              const SizedBox(height: 6),
                              Text(
                                isRunning ? (isWorking ? 'WORK' : 'PAUSE') : '',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                height: 50,
                child: OutlinedButton(
                  onPressed: resetTimer,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(width: 1.5),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'RESET',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
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

class TimerPainter extends CustomPainter {
  final double progress;

  TimerPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 6.0;
    final center = size.center(Offset.zero);
    final radius = size.width / 2;

    final progressPaint = Paint()
      ..color = Colors.blueAccent
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      -pi / 2,
      2 * pi * (1 - progress),
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
