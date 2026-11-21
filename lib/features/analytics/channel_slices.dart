import '../../core/theme/oobli_colors.dart';
import '../../data/models/category.dart';
import '../../ui/widgets/charts.dart';

/// Donut slices for spend by payment channel: the top three channels plus
/// "Other". Shared by the dashboard and Analytics so both read the same.
List<DonutSlice> channelSlices(OobliColors c, Map<TxChannel, double> channels) {
  final palette = [c.primary, c.secondary, c.accent, c.warning];
  final top = channels.entries.take(3).toList();
  final rest = channels.entries.skip(3).fold<double>(0, (s, e) => s + e.value);
  return [
    for (final (i, e) in top.indexed) DonutSlice(label: e.key.label, value: e.value, color: palette[i]),
    if (rest > 0) DonutSlice(label: 'Other', value: rest, color: palette[3]),
  ];
}
