import 'package:flutter/material.dart';

/// A compact DataTable header that opens a column-specific text filter.
///
/// Unlike the global search action, every instance controls only the values in
/// its own column, matching the familiar Excel filter workflow.
class ExcelColumnFilterHeader extends StatelessWidget {
  const ExcelColumnFilterHeader({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  static bool matches(
    Map<String, String> filters,
    Map<String, Object?> row,
  ) {
    return filters.entries.every((entry) {
      final filter = entry.value.trim().toLowerCase();
      if (filter.isEmpty) {
        return true;
      }
      return (row[entry.key]?.toString() ?? '').toLowerCase().contains(filter);
    });
  }

  Future<void> _showFilter(BuildContext context) async {
    final controller = TextEditingController(text: value);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Filter: $label'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (text) => Navigator.pop(dialogContext, text),
          decoration: InputDecoration(
            hintText: 'Contains...',
            suffixIcon: controller.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear',
                    onPressed: () => controller.clear(),
                    icon: const Icon(Icons.clear),
                  ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, ''),
            child: const Text('Clear'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result != null) {
      onChanged(result.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = value.trim().isNotEmpty;
    return InkWell(
      onTap: () => _showFilter(context),
      borderRadius: BorderRadius.circular(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 3),
          Icon(
            active ? Icons.filter_alt : Icons.filter_alt_outlined,
            size: 16,
            color: active ? Theme.of(context).colorScheme.primary : null,
          ),
        ],
      ),
    );
  }
}
