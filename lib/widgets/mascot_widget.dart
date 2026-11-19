import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'mascot_painters_1.dart';
import 'mascot_painters_2.dart';
import 'mascot_painters_3.dart';
import 'mascot_painters_4.dart';
import 'mascot_painters_5.dart';
import 'mascot_painters_legacy.dart';

enum MascotMood { idle, happy, cheer, blink, surprised }

/// Placeholder mascot: painted shapes only (v1 constraint - no image assets).
/// It bobs while idle and bursts into confetti when `celebrationTick` changes,
/// which happens every time an item is marked as organized.
class MascotWidget extends StatefulWidget {
  const MascotWidget({
    super.key,
    required this.variant,
    required this.pack,
    this.size = 120,
    this.mood = MascotMood.idle,
    this.celebrationTick = 0,
  });

  final MascotVariant variant;
  final ThemePack pack;
  final double size;
  final MascotMood mood;
  final int celebrationTick;

  @override
  State<MascotWidget> createState() => _MascotWidgetState();
}

class _MascotWidgetState extends State<MascotWidget> with TickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);

  late final AnimationController _celebrate = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  @override
  void dispose() {
    _idle.dispose();
    _celebrate.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MascotWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.celebrationTick != oldWidget.celebrationTick && widget.celebrationTick > 0) {
      _celebrate.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge(<Listenable>[_idle, _celebrate]),
        builder: (BuildContext context, Widget? child) {
          final double bob = math.sin(_idle.value * math.pi * 2) * widget.size * 0.025;
          final double t = _celebrate.value;
          final double bounce = t == 0 ? 0.0 : math.sin(t * math.pi * 3) * (1 - t) * 0.2;

          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: <Widget>[
              if (t > 0)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ConfettiPainter(
                      progress: t,
                      colors: <Color>[widget.pack.seed, widget.pack.accent, const Color(0xFFFFD54F)],
                    ),
                  ),
                ),
              Transform.translate(
                offset: Offset(0, bob),
                child: Transform.scale(
                  scale: 1 + bounce,
                  child: CustomPaint(
                    size: Size.square(widget.size),
                    painter: MascotPainter(
                      variant: widget.variant,
                      pack: widget.pack,
                      mood: widget.mood,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Particle {
  const _Particle({
    required this.angle,
    required this.distance,
    required this.radius,
  });

  final double angle;
  final double distance;
  final double radius;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.progress, required this.colors}) {
    final math.Random random = math.Random(11);
    for (int i = 0; i < 26; i++) {
      _particles.add(_Particle(
        angle: random.nextDouble() * math.pi * 2,
        distance: 0.25 + random.nextDouble() * 0.5,
        radius: 2.5 + random.nextDouble() * 3,
      ));
    }
  }

  final double progress;
  final List<Color> colors;
  final List<_Particle> _particles = <_Particle>[];

  @override
  void paint(Canvas canvas, Size size) {
    final double opacity = (1 - progress).clamp(0.0, 1.0);
    final Offset center = Offset(size.width / 2, size.height / 2);
    for (int i = 0; i < _particles.length; i++) {
      final _Particle particle = _particles[i];
      final double travel = size.width * particle.distance * progress;
      final double gravity = 40 * progress * progress;
      final Offset offset = Offset(
        center.dx + math.cos(particle.angle) * travel,
        center.dy + math.sin(particle.angle) * travel + gravity,
      );
      final Paint paint = Paint()
        ..color = colors[i % colors.length].withAlpha((opacity * 255).round());
      canvas.drawCircle(offset, particle.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => oldDelegate.progress != progress;
}

class MascotPainter extends CustomPainter {
  MascotPainter({
    required this.variant,
    required this.pack,
    required this.mood,
  });

  final MascotVariant variant;
  final ThemePack pack;
  final MascotMood mood;

  @override
  void paint(Canvas canvas, Size size) {
    switch (variant) {
      case MascotVariant.bunny: paintMascotBunny(canvas, size, pack, mood); break;
      case MascotVariant.cat: paintMascotCat(canvas, size, pack, mood); break;
      case MascotVariant.robot: paintMascotRobot(canvas, size, pack, mood); break;
      case MascotVariant.axolotl: paintMascotAxolotl(canvas, size, pack, mood); break;
      case MascotVariant.ramen: paintMascotRamen(canvas, size, pack, mood); break;
      case MascotVariant.berry: paintMascotBerry(canvas, size, pack, mood); break;
      case MascotVariant.note: paintMascotNote(canvas, size, pack, mood); break;
      case MascotVariant.speaker: paintMascotSpeaker(canvas, size, pack, mood); break;
      case MascotVariant.redPanda: paintMascotRedPanda(canvas, size, pack, mood); break;
      case MascotVariant.quokka: paintMascotQuokka(canvas, size, pack, mood); break;
      case MascotVariant.seaOtter: paintMascotSeaOtter(canvas, size, pack, mood); break;
      case MascotVariant.cake: paintMascotCake(canvas, size, pack, mood); break;
      case MascotVariant.salad: paintMascotSalad(canvas, size, pack, mood); break;
      case MascotVariant.pizza: paintMascotPizza(canvas, size, pack, mood); break;
      case MascotVariant.blindfolded: paintMascotBlindfolded(canvas, size, pack, mood); break;
      case MascotVariant.strawHat: paintMascotStrawHat(canvas, size, pack, mood); break;
      case MascotVariant.ninja: paintMascotNinja(canvas, size, pack, mood); break;
      case MascotVariant.idol: paintMascotIdol(canvas, size, pack, mood); break;
      case MascotVariant.mage: paintMascotMage(canvas, size, pack, mood); break;
    }
  }

  @override
  bool shouldRepaint(covariant MascotPainter oldDelegate) =>
      oldDelegate.variant != variant ||
      oldDelegate.pack.id != pack.id ||
      oldDelegate.mood != mood;
}
