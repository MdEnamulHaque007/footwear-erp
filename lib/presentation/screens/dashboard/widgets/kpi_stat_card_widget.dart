import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A single KPI tile: module colour, emoji + icon, record count and a secondary
/// value line. Tapping navigates when [onTap] is supplied.
class KpiStatCardWidget extends StatefulWidget {
  const KpiStatCardWidget({
    super.key,
    required this.emoji,
    required this.icon,
    required this.title,
    required this.count,
    required this.color,
    this.value,
    this.valueIsCurrency = false,
    this.onTap,
  });

  final String emoji;
  final IconData icon;
  final String title;
  final int count;
  final Color color;

  /// Optional secondary line, e.g. a summed value or quantity.
  final double? value;

  /// Formats [value] as currency when true, otherwise as a plain number.
  final bool valueIsCurrency;
  final VoidCallback? onTap;

  @override
  State<KpiStatCardWidget> createState() => _KpiStatCardWidgetState();
}

class _KpiStatCardWidgetState extends State<KpiStatCardWidget> {
  bool _hovered = false;

  String get _formattedValue {
    final value = widget.value;
    if (value == null) return '';
    if (widget.valueIsCurrency) {
      return NumberFormat.compactCurrency(symbol: '').format(value);
    }
    return NumberFormat.decimalPattern().format(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MouseRegion(
      cursor: widget.onTap == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hovered ? -4 : 0, 0),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _hovered
                ? widget.color.withValues(alpha: 0.55)
                : theme.dividerColor,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: _hovered ? 0.22 : 0.08),
              blurRadius: _hovered ? 18 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: widget.color.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(widget.icon, color: widget.color, size: 20),
                    ),
                    const Spacer(),
                    Text(widget.emoji, style: const TextStyle(fontSize: 18)),
                  ],
                ),
                const Spacer(),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    NumberFormat.decimalPattern().format(widget.count),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: widget.color,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.title,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_formattedValue.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _formattedValue,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withValues(
                        alpha: 0.75,
                      ),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
