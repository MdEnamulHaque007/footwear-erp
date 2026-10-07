class ActivityLogEntry {
  const ActivityLogEntry({required this.id, required this.data});
  final String id;
  final Map<String, dynamic> data;
  String get module => data['module']?.toString() ?? '';
  String get action => data['action']?.toString() ?? '';
  String get actorUid => data['actorUid']?.toString() ?? '';
  String get actorName => data['actorName']?.toString() ?? 'Unknown';
  String get label =>
      data['recordLabel']?.toString() ??
      data['operation']?.toString() ??
      data['documentId']?.toString() ??
      '';
  String get status => data['status']?.toString() ?? 'success';
  DateTime? get createdAt {
    final value = data['createdAt'];
    return value is DateTime ? value : null;
  }
}
