part of 'scan_flow.dart';

/// Animated presence line: the coach avatar plus a thinking label.
class _ThinkingLine extends StatefulWidget {
  const _ThinkingLine({
    required this.mascot,
    required this.pack,
  });

  final MascotVariant mascot;
  final ThemePack pack;

  @override
  State<_ThinkingLine> createState() => _ThinkingLineState();
}

class _ThinkingLineState extends State<_ThinkingLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _dots = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _dots.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _dots,
      builder: (BuildContext context, Widget? child) {
        final int tick = (_dots.value * 3).floor().clamp(0, 2);
        final String label = 'Cellulose is thinking${'.' * (tick + 1)}';
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            MascotWidget(
              variant: widget.mascot,
              pack: widget.pack,
              size: 44,
              celebrationTick: 0,
            ),
            const SizedBox(width: 8),
            Text(
              label,
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
