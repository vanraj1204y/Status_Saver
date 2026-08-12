import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/strings.dart';
import '../../app/theme/app_colors.dart';
import '../../viewmodels/home_view_model.dart';
import '../shell.dart';

/// Animated in-app splash, shown right after the native splash. It warms up
/// the first status scan while the logo animates in.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900))
    ..forward();

  @override
  void initState() {
    super.initState();
    // Start scanning while the splash is visible so Home appears instantly.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeViewModel>().init();
    });
    Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 350),
          pageBuilder: (context, animation, secondary) => FadeTransition(
            opacity: animation,
            child: const Shell(),
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: CurvedAnimation(
                  parent: _controller, curve: Curves.easeOutBack),
              child: FadeTransition(
                opacity: _controller,
                child: Image.asset('assets/branding/splash_logo.png',
                    width: 130, height: 130),
              ),
            ),
            const SizedBox(height: 24),
            FadeTransition(
              opacity: CurvedAnimation(
                  parent: _controller,
                  curve: const Interval(0.35, 1, curve: Curves.easeOut)),
              child: Text(
                AppStrings.appName,
                style: theme.textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: 40),
            FadeTransition(
              opacity: CurvedAnimation(
                  parent: _controller,
                  curve: const Interval(0.6, 1, curve: Curves.easeOut)),
              child: const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                    strokeWidth: 2.6, color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
