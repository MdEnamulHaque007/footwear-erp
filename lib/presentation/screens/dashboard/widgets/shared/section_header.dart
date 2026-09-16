import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.subtitle, this.action});
  final String title;
  final String? subtitle;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
      if (subtitle case final value? when value.isNotEmpty) ...[
        const SizedBox(height: 3),
        Text(value, style: Theme.of(context).textTheme.bodySmall),
      ],
    ])),
    ..._actionElements(),
  ]);

  List<Widget> _actionElements() =>
      action == null ? const <Widget>[] : <Widget>[action!];
}
