/// ============================================================================
/// ফাইল: lib/domain/usecases/production/create_production_usecase.dart
/// স্তর: Domain Use Case | মডিউল: Production/Lasting
/// উদ্দেশ্য: Production/Lasting মডিউলের একটি নির্দিষ্ট business operation ও validation flow পরিচালনা করে।
/// প্রধান অংশ: CreateProductionUseCase
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:dartz/dartz.dart';
import '../../entities/production_entity.dart';
import '../../repositories/i_production_repository.dart';
import 'validate_production_quantity_usecase.dart';

class CreateProductionUseCase {
  CreateProductionUseCase(this._repository, this._validate);
  final IProductionRepository _repository;
  final ValidateProductionQuantityUseCase _validate;

  Future<Either<String, void>> call(ProductionEntity item) async {
    final error = await _validate(
      poTagNo: item.tagNo,
      productionDate: item.productionDate,
      candidateQuantity: item.quantity,
      poNo: item.poNo,
      article: item.article,
      color: item.color,
    );
    if (error != null) return Left(error);
    return _repository.createWithTransaction(item);
  }
}
