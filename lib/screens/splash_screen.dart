// v0.8.30: the app's opening screen (steward request 2026-11-21; logo by
// Leaf). Shows the brand lock-up on white for a ~2.2s hold - tap to skip -
// then fades into the app. The child builds from frame one, so startup work
// (state bootstrap, dashboard) runs while the splash shows; the dashboard
// widget tests keep passing untouched because the widgets they read stay in
// the tree beneath the overlay.
import 'dart:async';

import 'package:flutter/material.dart';

class SplashGate extends StatefulWidget {
  const SplashGate({super.key, required this.child});

  final Widget child;

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  static const Duration _hold = Duration(milliseconds: 2200);
  static const Duration _fade = Duration(milliseconds: 400);

  bool _visible = true;
  bool _fading = false;
  Timer? _holdTimer;
  Timer? _fadeTimer;

  @override
  void initState() {
    super.initState();
    _holdTimer = Timer(_hold, _beginFade);
  }

  void _beginFade() {
    if (!mounted || _fading) {
      return;
    }
    setState(() => _fading = true);
    _fadeTimer = Timer(_fade, _finish);
  }

  void _finish() {
    if (!mounted) {
      return;
    }
    setState(() => _visible = false);
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _fadeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double side = MediaQuery.of(context).size.shortestSide * 0.62;
    final double logoWidth = side.clamp(160.0, 420.0).toDouble();

    return Stack(
      children: <Widget>[
        Positioned.fill(child: widget.child),
        if (_visible)
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: _fading ? 0.0 : 1.0,
              duration: _fade,
              child: ColoredBox(
                color: Colors.white,
                child: GestureDetector(
                  key: const ValueKey<String>('splash_skip'),
                  behavior: HitTestBehavior.opaque,
                  onTap: _beginFade,
                  child: SafeArea(
                    child: Center(
                      child: Image.asset(
                        'assets/branding/logo.png',
                        key: const ValueKey<String>('splash_logo'),
                        width: logoWidth,
                        fit: BoxFit.contain,
                        semanticLabel: 'Stuff Organiser AI',
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}