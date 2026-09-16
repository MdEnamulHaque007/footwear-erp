import 'package:flutter/material.dart';

class ProjectSelector extends StatelessWidget {
  const ProjectSelector({super.key});
  @override
  Widget build(BuildContext context) => DropdownButtonHideUnderline(
    child: DropdownButton<String>(
      value: 'Footwear Innovations Ltd.',
      icon: const Icon(Icons.keyboard_arrow_down),
      items: const [DropdownMenuItem(value: 'Footwear Innovations Ltd.', child: Text('Footwear Innovations Ltd.'))],
      onChanged: (_) {},
    ),
  );
}
