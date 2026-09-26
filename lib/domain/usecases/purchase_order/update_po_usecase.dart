/// ============================================================================
/// ফাইল: lib/domain/usecases/purchase_order/update_po_usecase.dart
/// স্তর: Domain Use Case | মডিউল: Purchase Order
/// উদ্দেশ্য: Purchase Order মডিউলের একটি নির্দিষ্ট business operation ও validation flow পরিচালনা করে।
/// প্রধান অংশ: UpdatePOUseCase
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:dartz/dartz.dart';
import '../../entities/po_entity.dart';
import '../../repositories/i_po_repository.dart';
import 'validate_po_quantity_usecase.dart';

/// Updates a Purchase Order.
///
/// PO No uniqueness is re-checked with the edited record self-excluded, and the
/// Sl. is retained by the repository transaction.
class UpdatePOUseCase {
  UpdatePOUseCase(this._repository, [this._validate]);
  final IPORepository _repository;
  final ValidatePOQuantityUseCase? _validate;
  Future<Either<String, void>> call(POEntity item) async {
    if (item.poNo.trim().isEmpty) {
      return const Left('PO No is required');
    }
    final unique = await _repository.isPoNoUnique(
      item.poNo,
      excludeId: item.id,
    );
    if (!unique) {
      return Left('PO No ${item.poNo.trim()} already exists');
    }
    final error = _validate == null
        ? null
        : await _validate.validateCandidate(item);
    if (error != null) return Left(error);
    return _repository.updateWithTransaction(item);
  }
}
