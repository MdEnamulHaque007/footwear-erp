/// ============================================================================
/// ফাইল: lib/domain/usecases/timelapse/get_timelapse_data_usecase.dart
/// স্তর: Domain Use Case | মডিউল: Time-lapse Dashboard
/// উদ্দেশ্য: Time-lapse Dashboard মডিউলের একটি নির্দিষ্ট business operation ও validation flow পরিচালনা করে।
/// প্রধান অংশ: GetTimelapseDataUseCase
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:dartz/dartz.dart';

import '../../entities/timelapse/timelapse_config_entity.dart';
import '../../entities/timelapse/timelapse_data_entity.dart';
import '../../repositories/i_timelapse_repository.dart';

class GetTimelapseDataUseCase {
  GetTimelapseDataUseCase(this._repository);

  final ITimelapseRepository _repository;

  Future<Either<String, TimelapseData>> call(TimelapseConfig config) {
    return _repository.getTimelapseData(
      departments: config.departments,
      fromDate: config.fromDate,
      toDate: config.toDate,
      dataType: config.dataType,
    );
  }
}
