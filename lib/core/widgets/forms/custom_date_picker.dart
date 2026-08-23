import 'package:flutter/material.dart';

class CustomDatePicker extends StatelessWidget {
  const CustomDatePicker({super.key, required this.onSelected});
  final ValueChanged<DateTime> onSelected;
  @override
  Widget build(BuildContext context) => IconButton(
    icon: const Icon(Icons.calendar_month),
    onPressed: () async {
      final value = await showDatePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
        initialDate: DateTime.now(),
      );
      if (value != null) onSelected(value);
    },
  );
}
