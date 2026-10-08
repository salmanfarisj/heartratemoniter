import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// PulseX brand mark — Flutter re-implementation of the logo CSS:
///
///   cyan → azure → blue gradient heart (rotated square + two circles)
///   with an ink-black inset heart-shape and an ECG stroke through the
///   middle. Rendered with vanilla Flutter primitives so it scales
///   crisply on every density without rasterising.
///
/// Variants:
///  * [PulseXLogo]            — full-screen splash-friendly mark with
///                              dark backdrop, stacked heart + wordmark.
///  * [PulseXHomeLogo]        — compact mark for inline use on the
///                              home screen (transparent backdrop,
///                              heart + wordmark side-by-side).
///  * [PulseXAboutTile]       — list-row sized tile with mark + name.
class PulseXLogo extends StatelessWidget {
  final double size;
  final bool showWordmark;
  final Color background;

  const PulseXLogo({
    super.key,
    this.size = 120,
    this.showWordmark = true,
    this.background = AppColors.pulsexInk,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        color: background,
        padding: EdgeInsets.all(size * 0.25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: size,
              height: size * 0.86,
              child: CustomPaint(
                painter: _HeartMarkPainter(strokeWidth: size * 0.07),
              ),
            ),
            if (showWordmark) ...[
              SizedBox(height: size * 0.22),
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: size * 0.48,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -size * 0.022,
                    color: AppColors.paperWhite,
                  ),
                  children: [
                    const TextSpan(text: 'pulse'),
                    TextSpan(
                      text: 'X',
                      style: TextStyle(
                        foreground: Paint()
                          ..shader = AppColors.pulsexGradient.createShader(
                            Rect.fromLTWH(0, 0, size * 0.4, size * 0.6),
                          ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Compact, transparent-background PulseX mark for inline use on a
/// light surface (e.g. a card at the top of the home screen). Renders
/// the gradient heart with the ECG stroke and the two-tone "pulseX"
/// wordmark laid out side-by-side, matching the proportions of the
/// reference HTML/CSS logo.
class PulseXHomeLogo extends StatelessWidget {
  final double heartSize;
  final TextStyle? wordmarkStyle;
  final MainAxisAlignment alignment;

  const PulseXHomeLogo({
    super.key,
    this.heartSize = 56,
    this.wordmarkStyle,
    this.alignment = MainAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final style = wordmarkStyle ??
        const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.5,
          color: AppColors.inkBlack,
          height: 1.0,
        );

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: alignment,
      children: [
        SizedBox(
          width: heartSize,
          height: heartSize * 0.86,
          child: CustomPaint(
            painter: _HeartMarkPainter(strokeWidth: heartSize * 0.10),
          ),
        ),
        const SizedBox(width: 12),
        RichText(
          text: TextSpan(
            style: style,
            children: [
              const TextSpan(text: 'pulse'),
              TextSpan(
                text: 'X',
                style: TextStyle(
                  foreground: Paint()
                    ..shader = AppColors.pulsexGradient.createShader(
                      Rect.fromLTWH(
                        0,
                        0,
                        heartSize * 0.8,
                        style.fontSize ?? 32,
                      ),
                    ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// CustomPainter that draws the PulseX heart + ECG stroke.
///
/// Two circles + a rotated square (the canonical CSS heart technique)
/// form the gradient body; a smaller rounded rectangle punches a hole;
/// a poly-line of [AppColors.pulsexGradient]-stroked points lays the
/// ECG across the middle.
class _HeartMarkPainter extends CustomPainter {
  final double strokeWidth;

  _HeartMarkPainter({required this.strokeWidth});


  @override
  void paint(Canvas canvas, Size size) {
    final bodyRect = Offset.zero & size;
    final gradient = AppColors.pulsexGradient.createShader(bodyRect);

    // Single combined path: two circles overlapping a rotated square
    // gives the rounded heart silhouette.
    final heart = Path();
    final halfW = size.width * 0.5;
    // Two circles (top-left and top-right lobes) + the rotated square
    // that forms the bottom point. Approximated as ellipses anchored
    // at the upper corners and a triangle for the tip.
    final lobeR = size.width * 0.27;
    final left = Offset(halfW - lobeR * 0.65, lobeR + strokeWidth * 0.4);
    final right = Offset(halfW + lobeR * 0.65, lobeR + strokeWidth * 0.4);
    heart.addOval(Rect.fromCircle(center: left, radius: lobeR));
    heart.addOval(Rect.fromCircle(center: right, radius: lobeR));
    heart.moveTo(left.dx - lobeR * 0.5, size.height * 0.55);
    heart.lineTo(left.dx + lobeR * 0.4, size.height * 0.95);
    heart.lineTo(right.dx + lobeR * 0.5, size.height * 0.55);
    heart.lineTo(right.dx - lobeR * 0.4, size.height * 0.95);
    heart.close();

    canvas.save();
    canvas.translate(size.width * 0.5, size.height * 0.5);
    canvas.rotate(-0.785398); // -45°
    canvas.translate(-size.width * 0.5, -size.height * 0.5);

    canvas.drawPath(heart, Paint()..shader = gradient);
    canvas.restore();

    // Inset ink-black heart so we get the negative space heart-shape.
    final inset = size.width * 0.075;
    final inner = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(
          inset,
          inset,
          size.width - inset * 2,
          size.height - inset * 2,
        ),
        Radius.circular(size.width * 0.10),
      ));
    canvas.drawPath(
      inner,
      Paint()..color = AppColors.pulsexInk,
    );

    // ECG stroke across the middle, rotated to match the heart's diagonal.
    final ecgPoints = <Offset>[
      Offset(0, size.height * 0.5),
      Offset(size.width * 0.17, size.height * 0.5),
      Offset(size.width * 0.25, size.height * 0.5),
      Offset(size.width * 0.32, size.height * 0.14),
      Offset(size.width * 0.41, size.height * 0.86),
      Offset(size.width * 0.51, size.height * 0.36),
      Offset(size.width * 0.59, size.height * 0.5),
      Offset(size.width * 0.77, size.height * 0.5),
      Offset(size.width, size.height * 0.5),
    ];
    final ecgPath = Path()..moveTo(ecgPoints.first.dx, ecgPoints.first.dy);
    for (final p in ecgPoints.skip(1)) {
      ecgPath.lineTo(p.dx, p.dy);
    }
    final ecgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = strokeWidth
      ..shader = gradient;

    canvas.save();
    canvas.translate(size.width * 0.5, size.height * 0.5);
    canvas.rotate(0.785398); // +45° to counter the heart tilt
    canvas.translate(-size.width * 0.5, -size.height * 0.5);
    canvas.drawPath(ecgPath, ecgPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_HeartMarkPainter oldDelegate) =>
      oldDelegate.strokeWidth != strokeWidth;
}

/// Convenience launcher that calls [Navigator] back to the home tab when
/// used inside an About screen row.
class PulseXAboutTile extends StatelessWidget {
  const PulseXAboutTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 48,
          height: 48,
          child: CustomPaint(
            painter: _HeartMarkPainter(strokeWidth: 4),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PulseX',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              'Heart Rate Monitor & Activity Tracker',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }
}

/// Standalone PulseX heart mark — gradient body + ink-black inset +
/// gradient ECG stroke, sized to fit any container.
///
/// Used wherever the brand icon needs to appear by itself (e.g. the
/// home tab in the bottom nav, the app bar leading slot, the OS
/// launcher).
class PulseXHeart extends StatelessWidget {
  final double size;
  const PulseXHeart({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 0.86,
      child: CustomPaint(
        painter: _HeartMarkPainter(strokeWidth: size * 0.10),
      ),
    );
  }
}
