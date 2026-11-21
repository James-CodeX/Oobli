import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../domain/spending_stats.dart';

/// Short axis/tooltip money label: "12.4k", "850", "1.2M".
String _short(double v) {
  final a = v.abs();
  if (a >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
  if (a >= 10000) return '${(v / 1000).toStringAsFixed(0)}k';
  if (a >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
  return v.toStringAsFixed(0);
}

/// Rounds [v] up to a "nice" axis maximum (1, 2, 2.5, 5 × 10^n).
double _niceMax(double v) {
  if (v <= 0) return 1;
  final exp = math.pow(10, (math.log(v) / math.ln10).floor()).toDouble();
  for (final m in const [1.0, 2.0, 2.5, 5.0, 10.0]) {
    if (m * exp >= v) return m * exp;
  }
  return 10 * exp;
}

void _dashedLine(Canvas canvas, Offset a, Offset b, Paint paint, {double dash = 4, double gap = 4}) {
  final total = (b - a).distance;
  final dir = (b - a) / total;
  for (double d = 0; d < total; d += dash + gap) {
    canvas.drawLine(a + dir * d, a + dir * math.min(d + dash, total), paint);
  }
}

TextPainter _text(String s, TextStyle style) =>
    TextPainter(text: TextSpan(text: s, style: style), textDirection: TextDirection.ltr)..layout();

// ---------------------------------------------------------------------------
// Bar chart ("Today's Flow")
// ---------------------------------------------------------------------------

/// Slim capsule bars on soft tracks. The last bar (today) is highlighted with
/// a glow and value pill; tap any bar to inspect it. A dashed line marks the
/// average day.
class FlowBarChart extends StatefulWidget {
  const FlowBarChart({super.key, required this.points, this.height = 132, this.color});

  final List<SeriesPoint> points;
  final double height;
  final Color? color;

  @override
  State<FlowBarChart> createState() => _FlowBarChartState();
}

class _FlowBarChartState extends State<FlowBarChart> with SingleTickerProviderStateMixin {
  late final AnimationController _grow =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
  int? _selected;

  @override
  void didUpdateWidget(FlowBarChart old) {
    super.didUpdateWidget(old);
    if (old.points.length != widget.points.length) _selected = null;
  }

  @override
  void dispose() {
    _grow.dispose();
    super.dispose();
  }

  void _tap(Offset local, double width) {
    final n = widget.points.length;
    if (n == 0) return;
    final i = (local.dx / (width / n)).floor().clamp(0, n - 1);
    HapticFeedback.selectionClick();
    setState(() => _selected = _selected == i ? null : i);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return LayoutBuilder(
      builder: (context, box) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) => _tap(d.localPosition, box.maxWidth),
        child: AnimatedBuilder(
          animation: _grow,
          builder: (context, _) => CustomPaint(
            size: Size(box.maxWidth, widget.height),
            painter: _BarPainter(
              points: widget.points,
              progress: Curves.easeOutCubic.transform(_grow.value),
              highlight: _selected ?? widget.points.length - 1,
              color: widget.color ?? c.primary,
              track: c.surfaceVariant.withValues(alpha: 0.35),
              guide: c.secondaryText.withValues(alpha: 0.35),
              pillColor: c.primaryText,
              pillText: t.labelSmall.copyWith(color: c.background, fontWeight: FontWeight.w600),
              labelStyle: t.labelSmall.copyWith(color: c.secondaryText),
              activeLabelStyle: t.labelSmall.copyWith(color: c.primaryText, fontWeight: FontWeight.w700),
              avgStyle: t.labelSmall.copyWith(color: c.secondaryText, fontSize: 9),
            ),
          ),
        ),
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter({
    required this.points,
    required this.progress,
    required this.highlight,
    required this.color,
    required this.track,
    required this.guide,
    required this.pillColor,
    required this.pillText,
    required this.labelStyle,
    required this.activeLabelStyle,
    required this.avgStyle,
  });

  final List<SeriesPoint> points;
  final double progress;
  final int highlight;
  final Color color;
  final Color track;
  final Color guide;
  final Color pillColor;
  final TextStyle pillText;
  final TextStyle labelStyle;
  final TextStyle activeLabelStyle;
  final TextStyle avgStyle;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    const labelH = 18.0;
    const pillH = 20.0;
    const barW = 12.0;
    final top = pillH + 6;
    final chartH = size.height - labelH - top;
    final maxV = points.map((p) => p.value).fold<double>(0, math.max);
    final slot = size.width / points.length;
    final bottom = top + chartH;

    // Average guide.
    final avg = points.fold<double>(0, (s, p) => s + p.value) / points.length;
    if (maxV > 0 && avg > 0) {
      final y = bottom - chartH * (avg / maxV);
      _dashedLine(canvas, Offset(0, y), Offset(size.width - 22, y), Paint()..color = guide..strokeWidth = 1);
      _text('avg', avgStyle).paint(canvas, Offset(size.width - 18, y - 6));
    }

    for (var i = 0; i < points.length; i++) {
      final cx = slot * i + slot / 2;
      final active = i == highlight;
      final trackRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - barW / 2, top, barW, chartH),
        const Radius.circular(barW / 2),
      );
      canvas.drawRRect(trackRect, Paint()..color = track);

      final ratio = maxV <= 0 ? 0.0 : points[i].value / maxV;
      // Stagger each bar's growth slightly for a cascading entrance.
      final local = ((progress - i * 0.05) / (1 - points.length * 0.05)).clamp(0.0, 1.0);
      final h = math.max(points[i].value > 0 ? barW : 0.0, chartH * ratio * local);
      if (h > 0) {
        final rect = Rect.fromLTWH(cx - barW / 2, bottom - h, barW, h);
        final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(barW / 2));
        if (active) {
          canvas.drawRRect(
            rrect.inflate(1),
            Paint()
              ..color = color.withValues(alpha: 0.45)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
          );
        }
        canvas.drawRRect(
          rrect,
          Paint()
            ..shader = ui.Gradient.linear(
              rect.topCenter,
              rect.bottomCenter,
              active
                  ? [color, color.withValues(alpha: 0.75)]
                  : [color.withValues(alpha: 0.55), color.withValues(alpha: 0.25)],
            ),
        );
      }

      if (active && points[i].value > 0 && progress > 0.6) {
        final tp = _text(_short(points[i].value), pillText);
        final w = tp.width + 12;
        final left = (cx - w / 2).clamp(0.0, size.width - w);
        final pillTop = math.max(0.0, bottom - h - pillH - 6);
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(left, pillTop, w, pillH), const Radius.circular(pillH / 2)),
          Paint()..color = pillColor.withValues(alpha: ((progress - 0.6) / 0.4).clamp(0, 1)),
        );
        tp.paint(canvas, Offset(left + 6, pillTop + (pillH - tp.height) / 2));
      }

      final label = _text(points[i].label, active ? activeLabelStyle : labelStyle);
      label.paint(canvas, Offset(cx - label.width / 2, bottom + 6));
    }
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      old.progress != progress || old.highlight != highlight || old.points != points || old.color != color;
}

// ---------------------------------------------------------------------------
// Line chart ("Spending Flow")
// ---------------------------------------------------------------------------

/// Smooth monotone area chart (never overshoots below zero) with dashed
/// gridlines, a glowing stroke and a draggable tooltip.
class FlowLineChart extends StatefulWidget {
  const FlowLineChart({super.key, required this.points, this.height = 190});

  final List<SeriesPoint> points;
  final double height;

  @override
  State<FlowLineChart> createState() => _FlowLineChartState();
}

class _FlowLineChartState extends State<FlowLineChart> with SingleTickerProviderStateMixin {
  late final AnimationController _draw =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..forward();
  int? _selected;

  static const _gutter = 30.0;

  @override
  void didUpdateWidget(FlowLineChart old) {
    super.didUpdateWidget(old);
    final changed = old.points.length != widget.points.length ||
        [for (var i = 0; i < old.points.length; i++) old.points[i].value != widget.points[i].value].any((x) => x);
    if (changed) {
      _selected = null;
      _draw.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _draw.dispose();
    super.dispose();
  }

  void _select(Offset local, double width) {
    final n = widget.points.length;
    if (n < 2) return;
    final step = (width - _gutter) / (n - 1);
    final i = ((local.dx - _gutter) / step).round().clamp(0, n - 1);
    if (i != _selected) {
      HapticFeedback.selectionClick();
      setState(() => _selected = i);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return LayoutBuilder(
      builder: (context, box) => GestureDetector(
        onPanDown: (d) => _select(d.localPosition, box.maxWidth),
        onPanUpdate: (d) => _select(d.localPosition, box.maxWidth),
        onPanEnd: (_) => setState(() => _selected = null),
        onTapUp: (_) => setState(() => _selected = null),
        child: AnimatedBuilder(
          animation: _draw,
          builder: (context, _) => CustomPaint(
            size: Size(box.maxWidth, widget.height),
            painter: _LinePainter(
              points: widget.points,
              progress: Curves.easeInOutCubic.transform(_draw.value),
              selected: _selected,
              gutter: _gutter,
              line: c.primary,
              lineEnd: Color.lerp(c.primary, c.accent, 0.55)!,
              surface: c.surface,
              grid: c.outline,
              axisStyle: t.labelSmall.copyWith(color: c.hint, fontSize: 9),
              labelStyle: t.labelSmall.copyWith(color: c.secondaryText),
              activeLabelStyle: t.labelSmall.copyWith(color: c.primaryText, fontWeight: FontWeight.w700),
              bubbleColor: c.primaryText,
              bubbleTitle: t.labelSmall.copyWith(color: c.background.withValues(alpha: 0.7)),
              bubbleValue: t.labelMedium.copyWith(color: c.background, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter({
    required this.points,
    required this.progress,
    required this.selected,
    required this.gutter,
    required this.line,
    required this.lineEnd,
    required this.surface,
    required this.grid,
    required this.axisStyle,
    required this.labelStyle,
    required this.activeLabelStyle,
    required this.bubbleColor,
    required this.bubbleTitle,
    required this.bubbleValue,
  });

  final List<SeriesPoint> points;
  final double progress;
  final int? selected;
  final double gutter;
  final Color line;
  final Color lineEnd;
  final Color surface;
  final Color grid;
  final TextStyle axisStyle;
  final TextStyle labelStyle;
  final TextStyle activeLabelStyle;
  final Color bubbleColor;
  final TextStyle bubbleTitle;
  final TextStyle bubbleValue;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    const labelH = 20.0;
    const top = 34.0; // room for the tooltip
    final bottom = size.height - labelH;
    final h = bottom - top;
    final left = gutter;
    final w = size.width - left - 6;
    final maxV = _niceMax(points.map((p) => p.value).fold<double>(0, math.max));
    final step = w / (points.length - 1);

    // Gridlines + axis labels (0, half, max).
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (final f in const [0.0, 0.5, 1.0]) {
      final y = bottom - h * f;
      _dashedLine(canvas, Offset(left, y), Offset(size.width, y), gridPaint, dash: 3, gap: 5);
      final tp = _text(_short(maxV * f), axisStyle);
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }

    final pts = [
      for (var i = 0; i < points.length; i++) Offset(left + i * step, bottom - h * (points[i].value / maxV)),
    ];
    final path = _monotonePath(pts);

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, left + w * progress + 8, size.height));

    final area = Path.from(path)
      ..lineTo(pts.last.dx, bottom)
      ..lineTo(pts.first.dx, bottom)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, top),
          Offset(0, bottom),
          [line.withValues(alpha: 0.32), line.withValues(alpha: 0.0)],
        ),
    );

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = ui.Gradient.linear(pts.first, pts.last, [line, lineEnd]);
    // Soft glow under the crisp line.
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = line.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawPath(path, stroke..strokeWidth = 2.6);
    canvas.restore();

    // End point: ringed dot with halo (once the line has drawn in).
    if (progress > 0.98 && selected == null) {
      final p = pts.last;
      canvas.drawCircle(p, 9, Paint()..color = lineEnd.withValues(alpha: 0.2));
      canvas.drawCircle(p, 5, Paint()..color = surface);
      canvas.drawCircle(p, 3.5, Paint()..color = lineEnd);
    }

    for (var i = 0; i < points.length; i++) {
      final tp = _text(points[i].label, i == selected ? activeLabelStyle : labelStyle);
      final x = (pts[i].dx - tp.width / 2).clamp(left - 4, size.width - tp.width);
      tp.paint(canvas, Offset(x, bottom + 6));
    }

    final s = selected;
    if (s != null) {
      final p = pts[s];
      _dashedLine(canvas, Offset(p.dx, top - 4), Offset(p.dx, bottom), Paint()..color = grid..strokeWidth = 1.2);
      canvas.drawCircle(p, 7, Paint()..color = surface);
      canvas.drawCircle(p, 5, Paint()..color = line);

      final title = _text(points[s].label, bubbleTitle);
      final value = _text(Fmt.kes(points[s].value), bubbleValue);
      final bw = math.max(title.width, value.width) + 16;
      final bh = title.height + value.height + 8;
      final bx = (p.dx - bw / 2).clamp(0.0, size.width - bw);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(bx, 0, bw, bh), const Radius.circular(8)),
        Paint()..color = bubbleColor,
      );
      title.paint(canvas, Offset(bx + 8, 4));
      value.paint(canvas, Offset(bx + 8, 4 + title.height));
    }
  }

  /// Fritsch–Carlson monotone cubic: smooth, but never overshoots the data
  /// (so spending can't appear to dip below zero between points).
  static Path _monotonePath(List<Offset> p) {
    final n = p.length;
    final path = Path()..moveTo(p[0].dx, p[0].dy);
    final dx = List<double>.generate(n - 1, (i) => p[i + 1].dx - p[i].dx);
    final slope = List<double>.generate(n - 1, (i) => (p[i + 1].dy - p[i].dy) / dx[i]);
    final m = List<double>.filled(n, 0);
    m[0] = slope[0];
    m[n - 1] = slope[n - 2];
    for (var i = 1; i < n - 1; i++) {
      m[i] = slope[i - 1] * slope[i] <= 0 ? 0 : (slope[i - 1] + slope[i]) / 2;
    }
    for (var i = 0; i < n - 1; i++) {
      if (slope[i] == 0) {
        m[i] = 0;
        m[i + 1] = 0;
        continue;
      }
      final a = m[i] / slope[i];
      final b = m[i + 1] / slope[i];
      final r = a * a + b * b;
      if (r > 9) {
        final tau = 3 / math.sqrt(r);
        m[i] = tau * a * slope[i];
        m[i + 1] = tau * b * slope[i];
      }
    }
    for (var i = 0; i < n - 1; i++) {
      final h = dx[i] / 3;
      path.cubicTo(p[i].dx + h, p[i].dy + m[i] * h, p[i + 1].dx - h, p[i + 1].dy - m[i + 1] * h, p[i + 1].dx,
          p[i + 1].dy);
    }
    return path;
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.progress != progress || old.selected != selected || old.points != points || old.line != line;
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

/// Slim donut with rounded, gapped segments on a soft track. The centre shows
/// [centerValue]/[centerLabel]; tapping a segment (or legend row) focuses it.
class DonutChart extends StatefulWidget {
  const DonutChart({
    super.key,
    required this.slices,
    this.size = 140,
    this.legend = LegendPosition.right,
    this.centerValue,
    this.centerLabel,
  });

  final List<DonutSlice> slices;
  final double size;
  final LegendPosition legend;
  final String? centerValue;
  final String? centerLabel;

  @override
  State<DonutChart> createState() => _DonutChartState();
}

class _DonutChartState extends State<DonutChart> {
  int? _focus;

  double get _total => widget.slices.fold<double>(0, (s, x) => s + x.value);

  void _toggle(int i) {
    HapticFeedback.selectionClick();
    setState(() => _focus = _focus == i ? null : i);
  }

  void _tapRing(Offset local) {
    final center = Offset(widget.size / 2, widget.size / 2);
    final v = local - center;
    final r = v.distance;
    if (r < widget.size * 0.28 || r > widget.size * 0.52 || _total <= 0) return;
    var angle = math.atan2(v.dy, v.dx) + math.pi / 2;
    if (angle < 0) angle += 2 * math.pi;
    var acc = 0.0;
    for (var i = 0; i < widget.slices.length; i++) {
      acc += widget.slices[i].value / _total * 2 * math.pi;
      if (angle <= acc) return _toggle(i);
    }
  }

  static String _pct(double ratio) {
    final v = ratio * 100;
    return v >= 10 || v == v.roundToDouble() ? '${v.round()}%' : '${v.toStringAsFixed(1)}%';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final total = _total;
    final f = _focus;
    final value = f == null ? widget.centerValue : _pct(total <= 0 ? 0 : widget.slices[f].value / total);
    final label = f == null ? widget.centerLabel : widget.slices[f].label;

    final ring = GestureDetector(
      onTapUp: (d) => _tapRing(d.localPosition),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 1100),
        curve: Curves.easeOutCubic,
        builder: (context, v, child) => CustomPaint(
          size: Size.square(widget.size),
          painter: _DonutPainter(
            values: [for (final s in widget.slices) s.value],
            colors: [for (final s in widget.slices) s.color],
            progress: v,
            focus: f,
            track: c.surfaceVariant.withValues(alpha: 0.35),
          ),
          child: child,
        ),
        child: SizedBox.square(
          dimension: widget.size,
          child: Center(
            child: AnimatedSwitcher(
              duration: Motion.fast,
              child: Column(
                key: ValueKey('$value$label'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (value != null)
                    Text(value, style: t.titleMedium.copyWith(fontWeight: FontWeight.w700, height: 1.1)),
                  if (label != null)
                    SizedBox(
                      width: widget.size * 0.55,
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.labelSmall.copyWith(color: c.secondaryText),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final rows = [
      for (final (i, s) in widget.slices.indexed)
        _LegendRow(
          color: s.color,
          label: s.label,
          value: total <= 0 ? '0%' : _pct(s.value / total),
          dimmed: f != null && f != i,
          onTap: () => _toggle(i),
        ),
    ];

    if (widget.legend == LegendPosition.bottom) {
      return Column(
        children: [
          ring,
          const SizedBox(height: Sp.md),
          Wrap(alignment: WrapAlignment.center, spacing: Sp.lg, runSpacing: Sp.xs, children: rows),
        ],
      );
    }
    return Row(
      children: [
        ring,
        const SizedBox(width: Sp.xl),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final r in rows) Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: r),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
    required this.value,
    required this.dimmed,
    required this.onTap,
  });

  final Color color;
  final String label;
  final String value;
  final bool dimmed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final c = context.colors;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedOpacity(
        duration: Motion.fast,
        opacity: dimmed ? 0.35 : 1,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2.5)),
            ),
            const SizedBox(width: Sp.sm),
            Flexible(
              child: Text(label, overflow: TextOverflow.ellipsis, style: t.labelMedium.copyWith(color: c.primaryText)),
            ),
            const SizedBox(width: Sp.sm),
            Text(value, style: t.labelMedium.copyWith(color: c.secondaryText, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.values,
    required this.colors,
    required this.progress,
    required this.focus,
    required this.track,
  });

  final List<double> values;
  final List<Color> colors;
  final double progress;
  final int? focus;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.115;
    final radius = (size.width - stroke) / 2 - 3;
    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: radius);
    canvas.drawCircle(rect.center, radius, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track);

    final total = values.fold<double>(0, (s, v) => s + v);
    if (total <= 0) return;
    final nonZero = values.where((v) => v > 0).length;
    // Rounded caps extend past the arc ends; reserve that plus a gap.
    final capAngle = (stroke / 2) / radius;
    final gap = nonZero > 1 ? 0.07 + capAngle * 2 : 0.0;
    var start = -math.pi / 2;
    final sweepTotal = 2 * math.pi * progress;
    for (var i = 0; i < values.length; i++) {
      if (values[i] <= 0) continue;
      final sweep = values[i] / total * sweepTotal;
      final visible = math.max(0.001, sweep - gap);
      final focused = focus == null || focus == i;
      canvas.drawArc(
        rect,
        start + gap / 2,
        visible,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = nonZero > 1 && sweep > gap ? StrokeCap.round : StrokeCap.butt
          ..strokeWidth = focus == i ? stroke * 1.25 : stroke
          ..color = focused ? colors[i] : colors[i].withValues(alpha: 0.3),
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.progress != progress || old.focus != focus || old.values != values || old.colors != colors;
}
