import 'package:flutter/material.dart';

import '../core/app_colors.dart';

/// Shown while Firebase resolves the stored session and the router decides
/// where to send the user.
///
/// Uses the same background as the native splash so the handover from the
/// Android launch screen to Flutter has no visible colour flash.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.brandNavy,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Logo(),
            SizedBox(height: 28),
            Text(
              'NEXA Admin',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Operations console',
              style: TextStyle(color: Colors.white60, fontSize: 13),
            ),
            SizedBox(height: 40),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation(AppColors.brandBlue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/branding/logo_foreground.png',
      width: 160,
      height: 160,
      // The launcher icon is the only branding asset; if it is ever missing
      // the splash should still render rather than throw during startup.
      errorBuilder: (_, _, _) => const Icon(
        Icons.hexagon_outlined,
        size: 96,
        color: AppColors.brandBlue,
      ),
    );
  }
}
