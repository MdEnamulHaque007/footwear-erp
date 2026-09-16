import 'package:flutter/material.dart';

class KpiCardWidget extends StatelessWidget {
  const KpiCardWidget({super.key, required this.title, required this.value, required this.subtitle, required this.icon, required this.color});
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 120),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
    child: Row(children: [
      CircleAvatar(backgroundColor: Colors.white.withValues(alpha: .72), child: Icon(icon, color: const Color(0xFF172033))),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 7),
        Text(value, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
        Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF667085))),
      ])),
    ]),
  );
}
