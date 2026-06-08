import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:audioplayers/audioplayers.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _playAudioAndNavigate();
  }

  Future<void> _playAudioAndNavigate() async {
    // Small delay before starting audio for impact
    await Future.delayed(const Duration(milliseconds: 300));

    // Play the satisfying chime
    try {
      await _audioPlayer.play(AssetSource('audio/splash_sound.mp3'));
    } catch (e) {
      debugPrint("Audio play failed: $e");
    }

    // Wait for animations to finish
    await Future.delayed(const Duration(milliseconds: 3200));

    // Route to dashboard
    if (mounted) {
      context.go('/dashboard');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // The Logo with elastic scale and a sweeping shimmer
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black45 : Colors.black12,
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(60),
                child: Image.asset(
                  'assets/logo.png',
                  width: 120,
                  height: 120,
                ),
              ),
            )
            .animate()
            .scale(
              duration: 1200.ms,
              curve: Curves.elasticOut,
              begin: const Offset(0, 0),
            )
            .shimmer(
              delay: 800.ms,
              duration: 1500.ms,
              color: Colors.white54,
            ),
            
            const SizedBox(height: 32),
            
            // App Name sliding up and fading in
            Text(
              'FinGuard',
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            )
            .animate()
            .fadeIn(delay: 500.ms, duration: 800.ms)
            .slideY(
              begin: 0.5,
              end: 0,
              duration: 800.ms,
              curve: Curves.easeOutCubic,
            ),
          ],
        ),
      ),
    );
  }
}
