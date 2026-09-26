/// ============================================================================
/// ফাইল: lib/domain/usecases/export/create_export_usecase.dart
/// স্তর: Domain Use Case | মডিউল: Export
/// উদ্দেশ্য: Export মডিউলের একটি নির্দিষ্ট business operation ও validation flow পরিচালনা করে।
/// প্রধান অংশ: CreateExportUseCase
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:dartz/dartz.dart';
import '../../entities/export_entity.dart';
import '../../repositories/i_export_repository.dart';
import 'validate_export_quantity_usecase.dart';

/// Creates an Export entry.
///
/// PO-driven entries are written through
/// [IExportRepository.createWithTransaction] so the cumulative Issue / Export
/// check and the write are atomic, which keeps two concurrent devices from
/// over-consuming the same Issue quantity.
class CreateExportUseCase {
  CreateExportUseCase(this._repository, this._validate);
  final IExportRepository _repository;
  final ValidateExportQuantityUseCase _validate;

  Future<Either<String, void>> call(ExportEntity item) async {
    if (item.poNo.isNotEmpty) {
      final error = await _validate(
        poNo: item.poNo,
        article: item.article,
        color: item.color,
        candidateQuantity: item.quantity,
        exportDate: item.exportDate,
      );
      if (error != null) return Left(error);
      return _repository.createWithTransaction(item);
    }
    return _repository.createExport(item);
  }
}
