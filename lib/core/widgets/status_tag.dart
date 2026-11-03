import 'package:flutter/material.dart';

/// A small pill that states a status in words AND a shape, so it still
/// reads for color-blind users and in grayscale.
///
/// [stage] picks the glyph: 0 empty ring, 1 half, 2 filled ring, 3 punched.
class StatusTag extends StatelessWidget {
  const StatusTag({
    super.key,
    required this.label,
    required this.stage,
    required this.color,
  });

  final String label;
  final int stage;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 10, 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomPaint(size: const Size.square(14), painter: _GlyphPainter(stage, color)),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: Color.alphaBlend(
                theme.colorScheme.onSurface.withValues(alpha: 0.35),
                color,
              ),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter(this.stage, this.color);
  final int stage;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 1.2;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = color;
    canvas.drawCircle(c, r, stroke);
    switch (stage) {
      case 1:
        canvas.drawArc(Rect.fromCircle(center: c, radius: r - 2), -1.5708, 3.1416, true, Paint()..color = color);
      case 2:
        canvas.drawCircle(c, r - 3, Paint()..color = color);
      case 3:
        canvas.drawCircle(c, r + 1.2, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_GlyphPainter old) => old.stage != stage || old.color != color;
}
