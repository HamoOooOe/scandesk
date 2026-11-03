import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The ScanDesk signature: an inspection-tag disc with twelve month
/// positions. A month with service work is a punched hole; the current
/// month wears a ring. It answers "when was this device last looked at?"
/// without a single line of text.
///
/// By default it is a solid teal tag with white holes. On a teal band
/// (login) pass [disc], [hole] and [ink] so it stays readable.
class PunchRing extends StatelessWidget {
  const PunchRing({
    super.key,
    required this.punchedMonths,
    this.size = 96,
    this.year,
    this.currentMonth,
    this.showMonthNumbers = false,
    this.disc,
    this.hole,
    this.ink,
  });

  /// Months (1 to 12) that have a punch.
  final Set<int> punchedMonths;
  final double size;
  final int? year;

  /// Month (1 to 12) to mark as "now".
  final int? currentMonth;
  final bool showMonthNumbers;

  /// The tag stock, what a hole shows through, and the ink for ticks,
  /// the current-month ring and numbers.
  final Color? disc;
  final Color? hole;
  final Color? ink;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final discColor = disc ?? scheme.primary;
    final holeColor = hole ?? scheme.surfaceContainerLowest;
    final inkColor = ink ?? scheme.onPrimary;

    return Semantics(
      label: 'Service record, ${punchedMonths.length} of 12 months punched',
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 1100),
        curve: Curves.easeOutExpo,
        builder: (context, progress, _) => SizedBox.square(
          dimension: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size.square(size),
                painter: _RingPainter(
                  punched: punchedMonths,
                  progress: progress,
                  currentMonth: currentMonth,
                  showNumbers: showMonthNumbers,
                  disc: discColor,
                  hole: holeColor,
                  ink: inkColor,
                ),
              ),
              if (year != null)
                Text(
                  '$year',
                  style: AppTheme.mono(context, size: size * 0.15).copyWith(color: inkColor),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.punched,
    required this.progress,
    required this.currentMonth,
    required this.showNumbers,
    required this.disc,
    required this.hole,
    required this.ink,
  });

  final Set<int> punched;
  final double progress;
  final int? currentMonth;
  final bool showNumbers;
  final Color disc, hole, ink;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final outer = size.width / 2;

    canvas.drawCircle(c, outer - 0.5, Paint()..color = disc);

    final ringRadius = outer * 0.72;
    final holeRadius = outer * 0.15;
    final order = punched.toList()..sort();
    final shade = Color.lerp(disc, const Color(0xFF000000), 0.5)!;

    for (var month = 1; month <= 12; month++) {
      final angle = -math.pi / 2 + (month - 1) * math.pi / 6;
      final p = c + Offset(math.cos(angle), math.sin(angle)) * ringRadius;

      if (punched.contains(month)) {
        // Each punch lands a little after the one before it.
        final rank = order.indexOf(month);
        final t = (progress * 1.7 - rank * 0.1).clamp(0.0, 1.0);
        final r = holeRadius * Curves.easeOutBack.transform(t);
        // The hole shows what is behind the tag; its top edge is shaded
        // like the cut edge of card stock.
        canvas.drawCircle(p, r, Paint()..color = shade);
        canvas.drawCircle(p + Offset(0, r * 0.14), r * 0.9, Paint()..color = hole);
      } else {
        canvas.drawCircle(p, holeRadius * 0.26, Paint()..color = ink.withValues(alpha: 0.55));
      }

      if (currentMonth == month) {
        canvas.drawCircle(
          p,
          holeRadius * 1.6,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(1.5, outer * 0.03)
            ..color = ink,
        );
      }

      if (showNumbers) {
        final tp = TextPainter(
          text: TextSpan(
            text: '$month',
            style: TextStyle(
              fontSize: outer * 0.1,
              color: ink.withValues(alpha: 0.85),
              fontWeight: FontWeight.w600,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final q = c + Offset(math.cos(angle), math.sin(angle)) * (ringRadius - holeRadius * 2.5);
        tp.paint(canvas, q - Offset(tp.width / 2, tp.height / 2));
      }
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.punched != punched ||
      old.currentMonth != currentMonth ||
      old.disc != disc ||
      old.hole != hole ||
      old.ink != ink;
}
