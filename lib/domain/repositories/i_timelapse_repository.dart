/// ============================================================================
/// ফাইল: lib/domain/repositories/i_timelapse_repository.dart
/// স্তর: Domain Repository Contract | মডিউল: Time-lapse Dashboard
/// উদ্দেশ্য: Time-lapse Dashboard data access-এর interface নির্ধারণ করে; implementation data layer-এ থাকে।
/// প্রধান অংশ: ITimelapseRepository
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:dartz/dartz.dart';

import '../entities/dashboard/department_option_entity.dart';
import '../entities/timelapse/timelapse_config_entity.dart';
import '../entities/timelapse/timelapse_data_entity.dart';

abstract class ITimelapseRepository {
  Future<Either<String, TimelapseData>> getTimelapseData({
    required List<DepartmentOption> departments,
    required DateTime fromDate,
    required DateTime toDate,
    required DataType dataType,
  });
}
