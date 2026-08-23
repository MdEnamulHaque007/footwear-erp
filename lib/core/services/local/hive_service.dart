import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  Future<void> initialize() => Hive.initFlutter();
}
