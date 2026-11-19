import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum MascotMood { idle, happy, cheer }

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
                    painter: _MascotPainter(
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

class _MascotPainter extends CustomPainter {
  _MascotPainter({
    required this.variant,
    required this.pack,
    required this.mood,
  });

  final MascotVariant variant;
  final ThemePack pack;
  final MascotMood mood;

  static const Color _ink = Color(0xFF2E2E38);

  @override
  void paint(Canvas canvas, Size size) {
    final void Function(Canvas, Size) painter = switch (variant) {
      MascotVariant.bunny => _paintBunny,
      MascotVariant.cat => _paintCat,
      MascotVariant.robot => _paintRobot,
      MascotVariant.axolotl => _paintAxolotl,
      MascotVariant.ramen => _paintRamen,
      MascotVariant.berry => _paintBerry,
      MascotVariant.note => _paintNote,
      MascotVariant.speaker => _paintSpeaker,
      MascotVariant.redPanda => _paintRedPanda,
      MascotVariant.quokka => _paintQuokka,
      MascotVariant.seaOtter => _paintSeaOtter,
      MascotVariant.cake => _paintCake,
      MascotVariant.salad => _paintSalad,
      MascotVariant.pizza => _paintPizza,
      MascotVariant.blindfolded => _paintBlindfolded,
      MascotVariant.strawHat => _paintStrawHat,
      MascotVariant.ninja => _paintNinja,
      MascotVariant.idol => _paintIdol,
      MascotVariant.mage => _paintMage,
    };
    painter(canvas, size);
  }

  void _paintBunny(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Paint body = Paint()..color = pack.accent;
    final Paint inner = Paint()..color = pack.seed;

    for (final double sign in <double>[-1, 1]) {
      canvas.save();
      canvas.translate(w / 2 + sign * w * 0.16, h * 0.26);
      canvas.rotate(sign * 0.16);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: w * 0.13, height: h * 0.32),
          Radius.circular(w * 0.065),
        ),
        body,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: w * 0.05, height: h * 0.22),
          Radius.circular(w * 0.025),
        ),
        inner,
      );
      canvas.restore();
    }

    final Offset head = Offset(w / 2, h * 0.6);
    final double r = w * 0.3;
    canvas.drawCircle(head, r, body);
    _paintFace(canvas, head, r);
  }

  void _paintCat(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Paint body = Paint()..color = pack.accent;
    final Offset head = Offset(w / 2, h * 0.6);
    final double r = w * 0.3;

    for (final double sign in <double>[-1, 1]) {
      final Path ear = Path()
        ..moveTo(head.dx + sign * r * 0.85, head.dy - r * 0.5)
        ..lineTo(head.dx + sign * r * 0.35, head.dy - r * 1.25)
        ..lineTo(head.dx + sign * r * 0.05, head.dy - r * 0.6)
        ..close();
      canvas.drawPath(ear, body);
    }
    canvas.drawCircle(head, r, body);
    _paintFace(canvas, head, r);

    final Paint whisker = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.012
      ..strokeCap = StrokeCap.round;
    for (final double sign in <double>[-1, 1]) {
      canvas.drawLine(
        Offset(head.dx + sign * r * 0.35, head.dy + r * 0.08),
        Offset(head.dx + sign * r * 0.95, head.dy - r * 0.02),
        whisker,
      );
      canvas.drawLine(
        Offset(head.dx + sign * r * 0.35, head.dy + r * 0.26),
        Offset(head.dx + sign * r * 0.95, head.dy + r * 0.34),
        whisker,
      );
    }
  }

  void _paintRobot(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Paint body = Paint()..color = pack.accent;
    final Paint face = Paint()..color = pack.seed;

    final Paint antenna = Paint()
      ..color = _ink
      ..strokeWidth = w * 0.02
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w / 2, h * 0.36), Offset(w / 2, h * 0.2), antenna);
    canvas.drawCircle(Offset(w / 2, h * 0.18), w * 0.05, face);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(w / 2, h * 0.58), width: w * 0.6, height: h * 0.48),
        Radius.circular(w * 0.14),
      ),
      body,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(w / 2, h * 0.57), width: w * 0.44, height: h * 0.3),
        Radius.circular(w * 0.08),
      ),
      face,
    );
    _paintFace(canvas, Offset(w / 2, h * 0.56), w * 0.16);
  }

  void _paintAxolotl(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Paint body = Paint()..color = pack.accent;
    final Offset head = Offset(w / 2, h * 0.58);
    final double r = w * 0.28;

    for (int i = 0; i < 3; i++) {
      for (final double sign in <double>[-1, 1]) {
        canvas.drawCircle(
          Offset(head.dx + sign * (r + w * 0.06), head.dy - r * 0.5 + i * r * 0.5),
          w * 0.045,
          body,
        );
      }
    }
    canvas.drawCircle(head, r, body);
    _paintFace(canvas, head, r);
  }

  void _paintRamen(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Paint bowl = Paint()..color = pack.accent;
    final Paint broth = Paint()..color = pack.seed;

    canvas.drawArc(
      Rect.fromCenter(center: Offset(w / 2, h * 0.6), width: w * 0.68, height: h * 0.4),
      0,
      math.pi,
      true,
      bowl,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w / 2, h * 0.4), width: w * 0.68, height: h * 0.2),
      broth,
    );

    final Paint noodle = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.02
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 3; i++) {
      final double x = w / 2 + (i - 1) * w * 0.16;
      final Path path = Path()
        ..moveTo(x - w * 0.06, h * 0.42)
        ..quadraticBezierTo(x, h * 0.27, x + w * 0.06, h * 0.42);
      canvas.drawPath(path, noodle);
    }
    _paintFace(canvas, Offset(w / 2, h * 0.6), w * 0.17);
  }

  void _paintBerry(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Paint body = Paint()..color = pack.accent;
    final Offset head = Offset(w / 2, h * 0.58);
    final double r = w * 0.28;

    final Path leaf = Path()
      ..moveTo(head.dx, head.dy - r)
      ..quadraticBezierTo(head.dx + w * 0.13, head.dy - r * 1.55, head.dx + w * 0.02, head.dy - r * 1.5)
      ..quadraticBezierTo(head.dx - w * 0.09, head.dy - r * 1.4, head.dx, head.dy - r)
      ..close();
    canvas.drawPath(leaf, Paint()..color = pack.seed);
    canvas.drawCircle(head, r, body);
    _paintFace(canvas, head, r);
  }

  void _paintNote(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Paint body = Paint()..color = pack.accent;
    final Paint stem = Paint()..color = pack.seed;
    final double x = w * 0.44;

    canvas.drawRect(Rect.fromLTWH(x, h * 0.2, w * 0.08, h * 0.5), stem);
    final Path flag = Path()
      ..moveTo(x + w * 0.08, h * 0.2)
      ..quadraticBezierTo(x + w * 0.34, h * 0.3, x + w * 0.22, h * 0.46)
      ..lineTo(x + w * 0.08, h * 0.42)
      ..close();
    canvas.drawPath(flag, stem);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x - w * 0.04, h * 0.72), width: w * 0.28, height: h * 0.2),
      body,
    );
    _paintFace(canvas, Offset(x - w * 0.04, h * 0.72), w * 0.1);
  }

  void _paintSpeaker(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Paint body = Paint()..color = pack.accent;
    final Paint cone = Paint()..color = pack.seed;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(w / 2, h * 0.58), width: w * 0.56, height: h * 0.56),
        Radius.circular(w * 0.12),
      ),
      body,
    );
    canvas.drawCircle(Offset(w / 2, h * 0.66), w * 0.14, cone);
    canvas.drawCircle(Offset(w / 2, h * 0.42), w * 0.06, cone);
    _paintFace(canvas, Offset(w / 2, h * 0.52), w * 0.13);
  }

  void _paintRedPanda(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Paint body = Paint()..color = pack.accent;
    final Paint dark = Paint()..color = pack.seed;
    final Offset head = Offset(w / 2, h * 0.6);
    final double r = w * 0.3;

    for (final double sign in <double>[-1, 1]) {
      canvas.drawCircle(
        Offset(head.dx + sign * r * 0.78, head.dy - r * 0.85),
        w * 0.09,
        dark,
      );
    }
    canvas.drawCircle(head, r, body);
    final Paint cheek = Paint()..color = pack.seed.withAlpha(120);
    canvas.drawCircle(Offset(head.dx - r * 0.62, head.dy + r * 0.2), r * 0.3, cheek);
    canvas.drawCircle(Offset(head.dx + r * 0.62, head.dy + r * 0.2), r * 0.3, cheek);
    _paintFace(canvas, head, r);
  }

  void _paintQuokka(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Paint body = Paint()..color = pack.accent;
    final Paint inner = Paint()..color = pack.seed;
    final Offset head = Offset(w / 2, h * 0.6);
    final double r = w * 0.3;

    for (final double sign in <double>[-1, 1]) {
      final Path ear = Path()
        ..addOval(
          Rect.fromCenter(
            center: Offset(head.dx + sign * r * 0.8, head.dy - r * 0.8),
            width: w * 0.14,
            height: h * 0.18,
          ),
        );
      canvas.drawPath(ear, body);
    }
    canvas.drawCircle(head, r, body);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(head.dx, head.dy + r * 0.35),
        width: r * 0.9,
        height: r * 0.5,
      ),
      inner.withAlpha(110),
    );
    _paintFace(canvas, head, r);
  }

  void _paintSeaOtter(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Paint body = Paint()..color = pack.accent;
    final Offset head = Offset(w / 2, h * 0.58);
    final double r = w * 0.29;

    for (final double sign in <double>[-1, 1]) {
      canvas.drawCircle(
        Offset(head.dx + sign * r * 0.85, head.dy - r * 0.72),
        w * 0.06,
        body,
      );
    }
    canvas.drawCircle(head, r, body);
    final Paint muzzle = Paint()..color = pack.seed.withAlpha(120);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(head.dx, head.dy + r * 0.32),
        width: r * 0.85,
        height: r * 0.5,
      ),
      muzzle,
    );
    final Paint whisker = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.012
      ..strokeCap = StrokeCap.round;
    for (final double sign in <double>[-1, 1]) {
      canvas.drawLine(
        Offset(head.dx + sign * r * 0.4, head.dy + r * 0.3),
        Offset(head.dx + sign * r * 0.98, head.dy + r * 0.2),
        whisker,
      );
      canvas.drawLine(
        Offset(head.dx + sign * r * 0.4, head.dy + r * 0.44),
        Offset(head.dx + sign * r * 0.95, head.dy + r * 0.52),
        whisker,
      );
    }
    _paintFace(canvas, head, r);
  }

  void _paintCake(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Paint body = Paint()..color = pack.accent;
    final Paint icing = Paint()..color = pack.seed;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(w / 2, h * 0.68), width: w * 0.58, height: h * 0.3),
        Radius.circular(w * 0.06),
      ),
      body,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(w / 2, h * 0.5), width: w * 0.44, height: h * 0.2),
        Radius.circular(w * 0.06),
      ),
      body,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(w / 2, h * 0.42), width: w * 0.46, height: h * 0.08),
        Radius.circular(w * 0.04),
      ),
      icing,
    );
    canvas.drawCircle(Offset(w / 2, h * 0.3), w * 0.05, icing);
    _paintFace(canvas, Offset(w / 2, h * 0.6), w * 0.16);
  }

  void _paintSalad(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Paint bowl = Paint()..color = pack.accent;
    final Paint leaf = Paint()..color = pack.seed;

    canvas.drawArc(
      Rect.fromCenter(center: Offset(w / 2, h * 0.55), width: w * 0.72, height: h * 0.5),
      0,
      math.pi,
      true,
      bowl,
    );
    for (final double dx in <double>[-0.22, -0.05, 0.12, 0.26]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(w * (0.5 + dx), h * 0.4),
          width: w * 0.16,
          height: h * 0.13,
        ),
        leaf,
      );
    }
    canvas.drawCircle(Offset(w * 0.42, h * 0.44), w * 0.04, bowl);
    canvas.drawCircle(Offset(w * 0.6, h * 0.42), w * 0.035, bowl);
    _paintFace(canvas, Offset(w / 2, h * 0.56), w * 0.15);
  }

  void _paintPizza(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Paint crust = Paint()..color = pack.accent;
    final Paint cheese = Paint()..color = pack.seed;

    final Path slice = Path()
      ..moveTo(w / 2, h * 0.2)
      ..lineTo(w * 0.2, h * 0.78)
      ..lineTo(w * 0.8, h * 0.78)
      ..close();
    canvas.drawPath(slice, cheese);
    final Path rim = Path()
      ..moveTo(w * 0.2, h * 0.78)
      ..quadraticBezierTo(w / 2, h * 0.86, w * 0.8, h * 0.78)
      ..lineTo(w * 0.76, h * 0.72)
      ..quadraticBezierTo(w / 2, h * 0.79, w * 0.24, h * 0.72)
      ..close();
    canvas.drawPath(rim, crust);
    for (final Offset spot in const <Offset>[
      Offset(0.5, 0.36),
      Offset(0.4, 0.56),
      Offset(0.6, 0.56),
    ]) {
      canvas.drawCircle(Offset(w * spot.dx, h * spot.dy), w * 0.05, crust);
    }
    _paintFace(canvas, Offset(w / 2, h * 0.5), w * 0.12);
  }

  void _paintBlindfolded(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Paint body = Paint()..color = pack.accent;
    final Paint hair = Paint()..color = pack.seed;
    final Paint band = Paint()..color = _ink;

    final Offset head = Offset(w / 2, h * 0.58);
    final double r = w * 0.28;
    for (int i = -2; i <= 2; i++) {
      final Path spike = Path()
        ..moveTo(head.dx + i * r * 0.42 - r * 0.18, head.dy - r * 0.55)
        ..lineTo(head.dx + i * r * 0.42, head.dy - r * (1.25 + (i == 0 ? 0.25 : 0.0)))
        ..lineTo(head.dx + i * r * 0.42 + r * 0.18, head.dy - r * 0.55)
        ..close();
      canvas.drawPath(spike, hair);
    }
    canvas.drawCircle(head, r, body);
    _paintFace(canvas, head, r);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(head.dx, head.dy - r * 0.12),
          width: r * 1.9,
          height: r * 0.42,
        ),
        Radius.circular(r * 0.2),
      ),
      band,
    );
  }

  void _paintStrawHat(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Paint body = Paint()..color = pack.accent;
    final Paint hat = Paint()..color = pack.seed;

    final Offset head = Offset(w / 2, h * 0.58);
    final double r = w * 0.27;
    canvas.drawCircle(head, r, body);
    _paintFace(canvas, head, r);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(head.dx, head.dy - r * 0.68),
        width: r * 2.4,
        height: h * 0.1,
      ),
      hat,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(head.dx, head.dy - r * 0.9),
        width: r * 1.4,
        height: r * 1.1,
      ),
      math.pi,
      math.pi,
      true,
      hat,
    );
    final Paint scar = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.014
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(head.dx - r * 0.36, head.dy - r * 0.1),
      Offset(head.dx - r * 0.36, head.dy + r * 0.3),
      scar,
    );
    canvas.drawLine(
      Offset(head.dx - r * 0.5, head.dy + r * 0.06),
      Offset(head.dx - r * 0.22, head.dy + r * 0.06),
      scar,
    );
  }

  void _paintNinja(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Paint body = Paint()..color = pack.accent;
    final Paint band = Paint()..color = pack.seed;

    final Offset head = Offset(w / 2, h * 0.58);
    final double r = w * 0.28;
    canvas.drawCircle(head, r, body);
    _paintFace(canvas, head, r);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(head.dx, head.dy - r * 0.45),
          width: r * 2.1,
          height: r * 0.34,
        ),
        Radius.circular(r * 0.16),
      ),
      band,
    );
    for (final double sign in <double>[-1, 1]) {
      final Path tail = Path()
        ..moveTo(head.dx + sign * r, head.dy - r * 0.45)
        ..quadraticBezierTo(
          head.dx + sign * r * 1.35,
          head.dy - r * 0.6,
          head.dx + sign * r * 1.25,
          head.dy - r * 0.15,
        )
        ..lineTo(head.dx + sign * r * 1.05, head.dy - r * 0.3)
        ..close();
      canvas.drawPath(tail, band);
    }
  }

  void _paintIdol(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Paint body = Paint()..color = pack.accent;
    final Paint tail = Paint()..color = pack.seed;

    final Offset head = Offset(w / 2, h * 0.6);
    final double r = w * 0.28;
    for (final double sign in <double>[-1, 1]) {
      canvas.drawCircle(
        Offset(head.dx + sign * r * 0.95, head.dy - r * 0.15),
        w * 0.11,
        tail,
      );
      canvas.drawCircle(
        Offset(head.dx + sign * r * 1.08, head.dy + r * 0.45),
        w * 0.08,
        tail,
      );
    }
    canvas.drawCircle(head, r, body);
    _paintFace(canvas, head, r);
    for (final double sign in <double>[-1, 1]) {
      final Path fringe = Path()
        ..moveTo(head.dx + sign * r * 0.2, head.dy - r)
        ..quadraticBezierTo(
          head.dx + sign * r * 0.75,
          head.dy - r * 0.75,
          head.dx + sign * r * 0.55,
          head.dy - r * 0.35,
        )
        ..close();
      canvas.drawPath(fringe, tail);
    }
    canvas.drawCircle(Offset(head.dx, head.dy - r * 1.02), w * 0.05, tail);
  }

  void _paintMage(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Paint body = Paint()..color = pack.accent;
    final Paint hat = Paint()..color = pack.seed;

    final Offset head = Offset(w / 2, h * 0.6);
    final double r = w * 0.27;
    canvas.drawCircle(head, r, body);
    _paintFace(canvas, head, r);
    final Path cone = Path()
      ..moveTo(head.dx, head.dy - r * 1.85)
      ..lineTo(head.dx - r * 0.95, head.dy - r * 0.55)
      ..lineTo(head.dx + r * 0.95, head.dy - r * 0.55)
      ..close();
    canvas.drawPath(cone, hat);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(head.dx, head.dy - r * 0.58),
          width: r * 2.2,
          height: h * 0.07,
        ),
        Radius.circular(w * 0.03),
      ),
      hat,
    );
    canvas.drawCircle(Offset(head.dx, head.dy - r * 2.05), w * 0.045, hat);
    canvas.drawCircle(Offset(head.dx + r * 0.35, head.dy - r * 2.0), w * 0.03, hat);
  }

  void _paintFace(Canvas canvas, Offset center, double r) {
    final bool happy = mood != MascotMood.idle;
    final double eyeY = center.dy - r * 0.12;
    final double eyeDx = r * 0.36;

    if (happy) {
      final Paint arc = Paint()
        ..color = _ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.1
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(center.dx - eyeDx, eyeY), radius: r * 0.2),
        0.15 * math.pi,
        0.7 * math.pi,
        false,
        arc,
      );
      canvas.drawArc(
        Rect.fromCircle(center: Offset(center.dx + eyeDx, eyeY), radius: r * 0.2),
        0.15 * math.pi,
        0.7 * math.pi,
        false,
        arc,
      );
    } else {
      final Paint eye = Paint()..color = _ink;
      canvas.drawCircle(Offset(center.dx - eyeDx, eyeY), r * 0.12, eye);
      canvas.drawCircle(Offset(center.dx + eyeDx, eyeY), r * 0.12, eye);
    }

    final Paint blush = Paint()..color = pack.accent.withAlpha(90);
    canvas.drawCircle(Offset(center.dx - eyeDx * 1.5, center.dy + r * 0.18), r * 0.13, blush);
    canvas.drawCircle(Offset(center.dx + eyeDx * 1.5, center.dy + r * 0.18), r * 0.13, blush);

    if (mood == MascotMood.cheer) {
      final Paint mouth = Paint()..color = _ink;
      canvas.drawOval(
        Rect.fromCenter(
          center: center.translate(0, r * 0.22),
          width: r * 0.3,
          height: r * 0.34,
        ),
        mouth,
      );
    } else {
      final Paint mouth = Paint()
        ..color = _ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.09
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCenter(
          center: center.translate(0, -r * 0.08),
          width: r * 0.36,
          height: r * 0.28,
        ),
        0.12 * math.pi,
        0.76 * math.pi,
        false,
        mouth,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MascotPainter oldDelegate) =>
      oldDelegate.variant != variant ||
      oldDelegate.pack.id != pack.id ||
      oldDelegate.mood != mood;
}
