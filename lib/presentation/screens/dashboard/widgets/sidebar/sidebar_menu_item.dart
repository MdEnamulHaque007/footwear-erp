import 'package:flutter/material.dart';

class SidebarMenuItem extends StatelessWidget {
  const SidebarMenuItem({super.key, required this.icon, required this.label, required this.onTap, this.active = false, this.compact = false, this.indent = false});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final bool compact;
  final bool indent;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(indent && !compact ? 24 : 8, 2, 8, 2),
    child: Tooltip(message: compact ? label : '', child: Material(
      color: active ? const Color(0xFF1976D2) : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11), child: Row(children: [
          Icon(icon, size: 20, color: active ? Colors.white : const Color(0xFFB8C4D3)),
          if (!compact) ...[const SizedBox(width: 12), Expanded(child: Text(label, style: TextStyle(color: active ? Colors.white : const Color(0xFFB8C4D3), fontWeight: active ? FontWeight.w700 : FontWeight.w500)))],
        ])),
      ),
    )),
  );
}
