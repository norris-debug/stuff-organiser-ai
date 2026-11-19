part of 'scan_flow.dart';

/// v0.8 render-wait loader (Cellulose's locked design, translated from
/// CSS to Flutter): the chosen mascot spins gently with a slight bounce
/// while three dots orbit it, with the wait line underneath. Wired into
/// the photo-submitted wait so the render never looks silent; the
/// visible state holds at least ~1.5s (the analyze path enforces the
/// floor). Error wobble + tap-to-retry lands with the Cellulose lane
/// wiring (v0.8.x) - no error path exists in the interim route yet.
class RenderLoader extends StatefulWidget {
  const RenderLoader({
    super.key,
    required this.mascot,
    required this.pack,
  });

  final MascotVariant mascot;
  final ThemePack pack;

  @override
  State<RenderLoader> createState() => _RenderLoaderState();
}

class _RenderLoaderState extends State<RenderLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _spin,
      builder: (BuildContext context, Widget? child) {
        final double t = _spin.value;
        final double bob = math.sin(t * math.pi * 2) * 3;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: 120,
              height: 96,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  Transform.rotate(
                    angle: t * math.pi * 2,
                    child: Transform.translate(
                      offset: Offset(0, bob),
                      child: MascotWidget(
                        variant: widget.mascot,
                        pack: widget.pack,
                        size: 56,
                        celebrationTick: 0,
                      ),
                    ),
                  ),
                  for (int i = 0; i < 3; i++)
                    Transform.translate(
                      offset: Offset(
                        math.cos(t * math.pi * 2 + i * 2 * math.pi / 3) * 52,
                        math.sin(t * math.pi * 2 + i * 2 * math.pi / 3) * 30,
                      ),
                      child: Opacity(
                        opacity:
                            0.55 +
                            0.45 *
                                ((math.sin(t * math.pi * 2 + i * 2 * math.pi / 3) +
                                        1) /
                                    2),
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: widget.pack.seed,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Getting your tidy render ready...',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        );
      },
    );
  }
}
