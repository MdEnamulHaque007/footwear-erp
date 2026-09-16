import 'package:flutter/material.dart';

class DateRangeSelector extends StatefulWidget {
  const DateRangeSelector({super.key});
  @override
  State<DateRangeSelector> createState() => _DateRangeSelectorState();
}
class _DateRangeSelectorState extends State<DateRangeSelector> {
  String _value = 'This Month';
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(border: Border.all(color: Theme.of(context).colorScheme.outlineVariant), borderRadius: BorderRadius.circular(10)),
    child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: DropdownButtonHideUnderline(child: DropdownButton<String>(
      value: _value, isDense: true,
      items: const ['Today', 'This Week', 'This Month', 'Last 30 Days'].map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => _value = value);
        }
      },
    ))),
  );
}
