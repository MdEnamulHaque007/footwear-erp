/// ============================================================================
/// ফাইল: lib/presentation/blocs/cutting/cutting_event.dart
/// স্তর: Presentation BLoC | মডিউল: Cutting
/// উদ্দেশ্য: Cutting screen-এর event গ্রহণ করে state তৈরি এবং UI update নিয়ন্ত্রণ করে।
/// প্রধান অংশ: CuttingEvent, LoadCuttingList, LoadMoreCuttingList, SearchCutting, ClearSearchCutting, RefreshCutting, LoadCuttingDetail, CreateCutting, UpdateCutting, DeleteCutting
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import '../../../domain/entities/cutting_entity.dart';

sealed class CuttingEvent {
  const CuttingEvent();
}

class LoadCuttingList extends CuttingEvent {
  const LoadCuttingList({this.limit = 20});

  final int limit;
}

class LoadMoreCuttingList extends CuttingEvent {}

class SearchCutting extends CuttingEvent {
  SearchCutting(this.query);
  final String query;
}

class ClearSearchCutting extends CuttingEvent {}

class RefreshCutting extends CuttingEvent {
  const RefreshCutting({this.limit = 20});

  final int limit;
}

class LoadCuttingDetail extends CuttingEvent {
  LoadCuttingDetail(this.id, {this.initialItem});
  final String id;
  final CuttingEntity? initialItem;
}

class CreateCutting extends CuttingEvent {
  CreateCutting(this.item);
  final CuttingEntity item;
}

class UpdateCutting extends CuttingEvent {
  UpdateCutting(this.item);
  final CuttingEntity item;
}

class DeleteCutting extends CuttingEvent {
  DeleteCutting(this.id);
  final String id;
}

class LoadPONoList extends CuttingEvent {}

class SelectPO extends CuttingEvent {
  SelectPO(this.poNo);
  final String poNo;
}

class LoadPOArticles extends CuttingEvent {
  LoadPOArticles(this.poNo);
  final String poNo;
}

class LoadArticleColors extends CuttingEvent {
  LoadArticleColors(this.poNo, this.article);
  final String poNo;
  final String article;
}

class LoadPOQuantity extends CuttingEvent {
  LoadPOQuantity(this.poNo, this.article, this.color, {this.excludingId});
  final String poNo;
  final String article;
  final String color;
  final String? excludingId;
}

class ValidateCutting extends CuttingEvent {
  ValidateCutting(
    this.poNo,
    this.article,
    this.color,
    this.poQuantity,
    this.quantity,
    {this.excludingId},
  );
  final String poNo;
  final String article;
  final String color;
  final int poQuantity;
  final int quantity;
  final String? excludingId;
}
