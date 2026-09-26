/// ============================================================================
/// ফাইল: lib/domain/entities/dashboard/dashboard_activity_entity.dart
/// স্তর: Domain Entity | মডিউল: Dashboard
/// উদ্দেশ্য: Dashboard মডিউলের framework-independent business data ও হিসাবযোগ্য property সংজ্ঞায়িত করে।
/// প্রধান অংশ: DashboardActivityEntity
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

/// A single entry in the "Recent Activities" feed.
///
/// Built by merging the newest documents from every production collection, so
/// [module] identifies which one it came from and [relativeTime] renders the
/// familiar "3h ago" style label without the caller doing date maths.
class DashboardActivityEntity extends Equatable {
  const DashboardActivityEntity({
    required this.id,
    required this.module,
    required this.action,
    required this.description,
    required this.timestamp,
    this.userId = '',
  });

  final String id;
  final String module;
  final String action;
  final String description;
  final DateTime timestamp;
  final String userId;

  /// Human-readable age, e.g. `just now`, `5m ago`, `3h ago`, `2d ago`.
  ///
  /// Falls back to an absolute date once the entry is older than a week, where
  /// a relative label stops being useful.
  String get relativeTime {
    final diff = DateTime.now().difference(timestamp);
    if (diff.isNegative) return 'just now';
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('dd MMM yyyy').format(timestamp);
  }

  @override
  List<Object?> get props => [id, module, action, description, timestamp, userId];
}
