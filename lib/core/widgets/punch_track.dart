import 'package:flutter/material.dart';

/// A row of stations that gets punched as work moves forward:
/// Open, Assigned, In progress, Resolved.
///
/// [stage] is the index of the current station (0 to 3). Every station
/// before it is a punched hole, the current one is a ring, the rest are
/// empty. When [stage] changes, the new hole is punched with a small
/// overshoot instead of just switching.
class PunchTrack extends StatelessWidget {
  const PunchTrack({
    super.key,
    required this.stage,
    required this.labels,
    required this.accent,
    this.compact = false,
    this.resolved = false,
  });

  final int stage;
  final List<String> labels;
  final Color accent;

  /// Compact rows (lists) skip the labels.
  final bool compact;

  /// When true the last station is punched too (the ticket is closed).
  final bool resolved;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final height = compact ? 22.0 : 52.0;

    return Semantics(
      label: labels[stage.clamp(0, labels.length - 1)],
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: stage + (resolved ? 1.0 : 0.0)),
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) => SizedBox(
          height: height,
          child: LayoutBuilder(
            builder: (context, box) {
              final stations = labels.length;
              final gap = box.maxWidth / stations;
              return Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _TrackPainter(
                        value: value,
                        stations: stations,
                        current: stage,
                        accent: accent,
                        ink: scheme.onSurface,
                        stock: scheme.surfaceContainerLowest,
                        faint: scheme.outlineVariant,
                        compact: compact,
                      ),
                    ),
                  ),
                  if (!compact)
                    for (var i = 0; i < stations; i++)
                      Positioned(
                        left: gap * i,
                        width: gap,
                        bottom: 0,
                        child: Text(
                          labels[i].toUpperCase(),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textStyle?.copyWith(
                            color: i == stage ? scheme.onSurface : scheme.onSurfaceVariant,
                            fontWeight: i == stage ? FontWeight.w700 : FontWeight.w600,
                          ),
                        ),
                      ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TrackPainter extends CustomPainter {
  _TrackPainter({
    required this.value,
    required this.stations,
    required this.current,
    required this.accent,
    required this.ink,
    required this.stock,
    required this.faint,
    required this.compact,
  });

  final double value;
  final int stations, current;
  final Color accent, ink, stock, faint;
  final bool compact;

  @override
  void paint(Canvas canvas, Size size) {
    final gap = size.width / stations;
    final y = compact ? size.height / 2 : 14.0;
    final r = compact ? 6.0 : 9.0;
    double cx(int i) => gap * i + gap / 2;

    // The rail between stations; the punched part is solid.
    final rail = Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = faint;
    canvas.drawLine(Offset(cx(0), y), Offset(cx(stations - 1), y), rail);
    final done = Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = ink;
    final reach = (value.clamp(0.0, stations - 1.0));
    canvas.drawLine(Offset(cx(0), y), Offset(cx(0) + (cx(stations - 1) - cx(0)) * reach / (stations - 1), y), done);

    for (var i = 0; i < stations; i++) {
      final center = Offset(cx(i), y);
      final punch = (value - i).clamp(0.0, 1.0);

      if (punch > 0) {
        // A punched hole: dark disc that overshoots as it lands.
        final scale = Curves.easeOutBack.transform(punch);
        canvas.drawCircle(center, r * scale, Paint()..color = ink);
        canvas.drawCircle(
          center + Offset(0, r * 0.18 * scale),
          r * 0.62 * scale,
          Paint()..color = stock.withValues(alpha: 0.10),
        );
      } else if (i == current) {
        canvas.drawCircle(center, r, Paint()..color = stock);
        canvas.drawCircle(
          center,
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..color = accent,
        );
        canvas.drawCircle(center, r * 0.32, Paint()..color = accent);
      } else {
        canvas.drawCircle(center, r * 0.62, Paint()..color = stock);
        canvas.drawCircle(
          center,
          r * 0.62,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6
            ..color = faint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_TrackPainter old) =>
      old.value != value || old.current != current || old.accent != accent || old.ink != ink;
}
