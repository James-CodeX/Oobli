import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../domain/spending_stats.dart';

// ---------------------------------------------------------------------------
// Bar chart ("Today's Flow")
// ---------------------------------------------------------------------------

/// Animated vertical bars with weekday labels. Tapping a bar reveals its value.
class FlowBarChart extends StatefulWidget {
  const FlowBarChart({super.key, required this.points, this.height = 120, this.color});

  final List<SeriesPoint> points;
  final double height;
  final Color? color;

  @override
  State<FlowBarChart> createState() => _FlowBarChartState();
}

class _FlowBarChartState extends State<FlowBarChart> {
  /// Headroom for the bouncy grow-in curve so bars never overflow.
  static const _overshoot = 1.12;

  int? _selected;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final maxV = widget.points.fold<double>(0, (m, p) => math.max(m, p.value));
    const labelH = 18.0;
    const valueH = 18.0;

    return SizedBox(
      height: widget.height + valueH,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < widget.points.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selected = _selected == i ? null : i);
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      height: valueH,
                      child: AnimatedOpacity(
                        opacity: _selected == i ? 1 : 0,
                        duration: Motion.fast,
                        child: FittedBox(
                          child: Text(
                            Fmt.compactKes(widget.points[i].value),
                            style: t.labelSmall.copyWith(color: c.primaryText),
                          ),
                        ),
                      ),
                    ),
                    TweenAnimationBuilder<double>(
                      key: ValueKey('${widget.points.length}-$i-${widget.points[i].value}'),
                      tween: Tween(begin: 0, end: maxV <= 0 ? 0 : widget.points[i].value / maxV),
                      duration: Duration(milliseconds: 500 + i * 60),
                      curve: Motion.emphasized,
                      builder: (context, v, _) => Container(
                        width: 24,
                        height: math.max(4, (widget.height - labelH - Sp.xs) / _overshoot * v.clamp(0, _overshoot)),
                        decoration: BoxDecoration(
                          color: widget.points[i].value <= 0
                              ? c.divider
                              : (_selected == null || _selected == i
                                  ? widget.color ?? c.primary
                                  : (widget.color ?? c.primary).withValues(alpha: 0.4)),
                          borderRadius: Rad.all(Rad.xs),
                        ),
                      ),
                    ),
                    const SizedBox(height: Sp.xs),
                    SizedBox(
                      height: labelH,
                      child: Text(
                        widget.points[i].label,
                        style: t.labelSmall.copyWith(color: c.secondaryText),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Line chart ("Spending Flow")
// ---------------------------------------------------------------------------

/// Smooth filled line chart that draws itself in; drag to scrub values.
class FlowLineChart extends StatefulWidget {
  const FlowLineChart({super.key, required this.points, this.height = 200});

  final List<SeriesPoint> points;
  final double height;

  @override
  State<FlowLineChart> createState() => _FlowLineChartState();
}

class _FlowLineChartState extends State<FlowLineChart> with SingleTickerProviderStateMixin {
  late final AnimationController _draw =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
  int? _selected;

  @override
  void didUpdateWidget(FlowLineChart old) {
    super.didUpdateWidget(old);
    if (old.points.length != widget.points.length ||
        !_sameValues(old.points, widget.points)) {
      _selected = null;
      _draw.forward(from: 0);
    }
  }

  static bool _sameValues(List<SeriesPoint> a, List<SeriesPoint> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i].value != b[i].value) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _draw.dispose();
    super.dispose();
  }

  void _select(Offset local, double width) {
    if (widget.points.length < 2) return;
    final step = width / (widget.points.length - 1);
    final i = (local.dx / step).round().clamp(0, widget.points.length - 1);
    if (i != _selected) {
      HapticFeedback.selectionClick();
      setState(() => _selected = i);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    const labelH = 24.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return GestureDetector(
          onPanDown: (d) => _select(d.localPosition, width),
          onPanUpdate: (d) => _select(d.localPosition, width),
          onPanEnd: (_) => setState(() => _selected = null),
          onTapUp: (_) => setState(() => _selected = null),
          child: SizedBox(
            height: widget.height,
            child: Column(
              children: [
                Expanded(
                  child: AnimatedBuilder(
                    animation: _draw,
                    builder: (context, _) => CustomPaint(
                      size: Size.infinite,
                      painter: _LinePainter(
                        values: [for (final p in widget.points) p.value],
                        progress: Curves.easeOutCubic.transform(_draw.value),
                        line: c.primary,
                        fill: c.primary,
                        dotBorder: c.surface,
                        guide: c.divider,
                        selected: _selected,
                        bubbleColor: c.surfaceVariant,
                        bubbleText: t.labelMedium.copyWith(color: c.primaryText),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: labelH,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (final p in widget.points)
                        Text(p.label, style: t.labelSmall.copyWith(color: c.secondaryText)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter({
    required this.values,
    required this.progress,
    required this.line,
    required this.fill,
    required this.dotBorder,
    required this.guide,
    required this.selected,
    required this.bubbleColor,
    required this.bubbleText,
  });

  final List<double> values;
  final double progress;
  final Color line;
  final Color fill;
  final Color dotBorder;
  final Color guide;
  final int? selected;
  final Color bubbleColor;
  final TextStyle bubbleText;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    const top = 28.0;
    const dotR = 5.0;
    final maxV = values.reduce(math.max);
    final h = size.height - top - dotR;
    final step = size.width / (values.length - 1);
    final pts = [
      for (var i = 0; i < values.length; i++)
        Offset(i * step, top + h - (maxV <= 0 ? 0 : values[i] / maxV) * h),
    ];

    // Smooth curve through all points (Catmull-Rom converted to cubic Béziers).
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 0; i < pts.length - 1; i++) {
      final p0 = i == 0 ? pts[i] : pts[i - 1];
      final p1 = pts[i];
      final p2 = pts[i + 1];
      final p3 = i + 2 < pts.length ? pts[i + 2] : p2;
      final c1 = p1 + (p2 - p0) / 6;
      final c2 = p2 - (p3 - p1) / 6;
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(-dotR, 0, size.width * progress + dotR * 2, size.height));

    final area = Path.from(path)
      ..lineTo(pts.last.dx, size.height)
      ..lineTo(pts.first.dx, size.height)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [fill.withValues(alpha: 0.22), fill.withValues(alpha: 0.04)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    for (final p in pts) {
      canvas.drawCircle(p, dotR, Paint()..color = line);
    }
    canvas.restore();

    if (selected != null) {
      final p = pts[selected!];
      canvas.drawLine(Offset(p.dx, top), Offset(p.dx, size.height), Paint()..color = guide..strokeWidth = 1.5);
      canvas.drawCircle(p, dotR + 3, Paint()..color = dotBorder);
      canvas.drawCircle(p, dotR + 1, Paint()..color = line);

      final tp = TextPainter(
        text: TextSpan(text: Fmt.compactKes(values[selected!]), style: bubbleText),
        textDirection: TextDirection.ltr,
      )..layout();
      final bw = tp.width + 16;
      final left = (p.dx - bw / 2).clamp(0.0, size.width - bw);
      final rect = RRect.fromRectAndRadius(Rect.fromLTWH(left, 0, bw, 22), const Radius.circular(6));
      canvas.drawRRect(rect, Paint()..color = bubbleColor);
      tp.paint(canvas, Offset(left + 8, 11 - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.progress != progress || old.selected != selected || old.values != values || old.line != line;
}

// ---------------------------------------------------------------------------
// Donut chart
// ---------------------------------------------------------------------------

@immutable
class DonutSlice {
  const DonutSlice({required this.label, required this.value, required this.color});

  final String label;
  final double value;
  final Color color;
}

enum LegendPosition { right, bottom }

/// Thick donut with gaps between segments, sweeping in clockwise from 12 o'clock.
class DonutChart extends StatelessWidget {
  const DonutChart({
    super.key,
    required this.slices,
    this.size = 180,
    this.legend = LegendPosition.right,
    this.center,
  });

  final List<DonutSlice> slices;
  final double size;
  final LegendPosition legend;
  final Widget? center;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final total = slices.fold<double>(0, (s, x) => s + x.value);
    final ring = TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => CustomPaint(
        size: Size.square(size),
        painter: _DonutPainter(
          values: [for (final s in slices) s.value],
          colors: [for (final s in slices) s.color],
          progress: v,
          gapColor: c.surface,
          empty: c.divider,
        ),
        child: child,
      ),
      child: SizedBox.square(dimension: size, child: Center(child: center)),
    );

    final legendItems = [
      for (final s in slices)
        _LegendRow(
          color: s.color,
          label: s.label,
          value: total <= 0 ? '0%' : _pct(s.value / total),
        ),
    ];

    if (legend == LegendPosition.bottom) {
      return Column(
        children: [
          ring,
          const SizedBox(height: Sp.md),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: Sp.md,
            runSpacing: Sp.sm,
            children: legendItems,
          ),
        ],
      );
    }
    return Row(
      children: [
        ring,
        const SizedBox(width: Sp.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final item in legendItems)
                Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: item),
            ],
          ),
        ),
      ],
    );
  }

  static String _pct(double ratio) {
    final v = ratio * 100;
    return v == v.roundToDouble() || v >= 10 ? '${v.round()}%' : '${v.toStringAsFixed(1)}%';
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.color, required this.label, required this.value});

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: Sp.sm),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: t.labelMedium.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: Sp.sm),
        Text(value, style: t.labelMedium.copyWith(color: context.colors.secondaryText, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.values,
    required this.colors,
    required this.progress,
    required this.gapColor,
    required this.empty,
  });

  final List<double> values;
  final List<Color> colors;
  final double progress;
  final Color gapColor;
  final Color empty;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.2;
    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: (size.width - stroke) / 2);
    final total = values.fold<double>(0, (s, v) => s + v);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    if (total <= 0) {
      canvas.drawArc(rect, 0, math.pi * 2, false, paint..color = empty);
      return;
    }

    const gap = 0.045; // radians between segments
    final nonZero = values.where((v) => v > 0).length;
    var start = -math.pi / 2;
    final sweepTotal = math.pi * 2 * progress;
    for (var i = 0; i < values.length; i++) {
      if (values[i] <= 0) continue;
      final sweep = values[i] / total * sweepTotal;
      final visible = nonZero > 1 ? math.max(0.0, sweep - gap) : sweep;
      canvas.drawArc(rect, start + (nonZero > 1 ? gap / 2 : 0), visible, false, paint..color = colors[i]);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.progress != progress || old.values != values || old.colors != colors;
}
