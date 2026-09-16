import 'package:flutter/material.dart';
import '../../../../../domain/entities/dashboard/dashboard_activity_entity.dart';
import '../shared/dashboard_card.dart';
import '../shared/section_header.dart';

class AuditLogWidget extends StatelessWidget {
  const AuditLogWidget({super.key, required this.activities});
  final List<DashboardActivityEntity> activities;
  @override
  Widget build(BuildContext context) => DashboardCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const SectionHeader(title: 'Audit Log', subtitle: 'Latest production activity'),
    const SizedBox(height: 8),
    if (activities.isEmpty) const Padding(padding: EdgeInsets.all(28), child: Center(child: Text('No recent activities')))
    else ...activities.take(6).map((activity) => ListTile(
      dense: true, contentPadding: EdgeInsets.zero, leading: const CircleAvatar(radius: 16, backgroundColor: Color(0xFFE8F5E9), child: Icon(Icons.check, color: Color(0xFF2E7D32), size: 18)),
      title: Text(activity.description, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(activity.userId.isEmpty ? activity.module : activity.userId), trailing: Text(activity.relativeTime, style: Theme.of(context).textTheme.bodySmall),
    )),
  ]));
}
