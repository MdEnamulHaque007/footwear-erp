/// ============================================================================
/// ফাইল: lib/presentation/blocs/master_lc/master_lc_event.dart
/// স্তর: Presentation BLoC | মডিউল: Master LC
/// উদ্দেশ্য: Master LC screen-এর event গ্রহণ করে state তৈরি এবং UI update নিয়ন্ত্রণ করে।
/// প্রধান অংশ: MasterLCEvent, LoadMasterLCList, LoadMoreMasterLC, MasterLCUpdated, CreateMasterLC, UpdateMasterLC, DeleteMasterLC, LoadMasterLCDetail, LoadPredefinedLists
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import '../../../domain/entities/master_lc_entity.dart';

sealed class MasterLCEvent {}

class LoadMasterLCList extends MasterLCEvent {
  LoadMasterLCList({this.limit = 20});
  final int limit;
}

class LoadMoreMasterLC extends MasterLCEvent {}

class MasterLCUpdated extends MasterLCEvent {
  MasterLCUpdated(this.items);
  final List<MasterLCEntity> items;
}

class CreateMasterLC extends MasterLCEvent {
  CreateMasterLC(this.item);
  final MasterLCEntity item;
}

class UpdateMasterLC extends MasterLCEvent {
  UpdateMasterLC(this.item);
  final MasterLCEntity item;
}

class DeleteMasterLC extends MasterLCEvent {
  DeleteMasterLC(this.id);
  final String id;
}

class LoadMasterLCDetail extends MasterLCEvent {
  LoadMasterLCDetail(this.id, {this.initialItem});
  final String id;
  final MasterLCEntity? initialItem;
}

/// Loads the predefined Project / Company lists for the form dropdowns.
class LoadPredefinedLists extends MasterLCEvent {}
