import 'package:flutter/material.dart';

/// Rounded pastel card used for the dashboard "bento" grid.
class BentoTile extends StatelessWidget {
  const BentoTile({
    super.key,
    required this.color,
    required this.child,
    this.border,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
  });

  final Color color;
  final Widget child;
  final Color? border;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(28),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: padding,
          decoration: border == null
              ? null
              : BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: border!, width: 1.5),
                ),
          child: child,
        ),
      ),
    );
  }
}

class RingProgress extends StatelessWidget {
  const RingProgress({
    super.key,
    required this.value,
    required this.color,
    required this.track,
    required this.child,
    this.size = 112,
    this.stroke = 16,
  });

  final double value;
  final Color color;
  final Color track;
  final Widget child;
  final double size;
  final double stroke;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(value.clamp(0, 1), color, track, stroke),
        child: Center(child: child),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.value, this.color, this.track, this.stroke);
  final double value;
  final Color color;
  final Color track;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final deflated = rect.deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(deflated, 0, 6.2832, false, paint..color = track);
    if (value > 0) {
      canvas.drawArc(
          deflated, -1.5708, 6.2832 * value, false, paint..color = color);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.color != color || old.track != track;
}
