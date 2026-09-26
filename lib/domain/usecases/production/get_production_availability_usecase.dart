/// ============================================================================
/// ফাইল: lib/domain/usecases/production/get_production_availability_usecase.dart
/// স্তর: Domain Use Case | মডিউল: Production/Lasting
/// উদ্দেশ্য: Production/Lasting মডিউলের একটি নির্দিষ্ট business operation ও validation flow পরিচালনা করে।
/// প্রধান অংশ: GetProductionAvailabilityUseCase, ProductionAvailability
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:dartz/dartz.dart';
import '../../repositories/i_production_repository.dart';
import '../../repositories/i_sewing_repository.dart';

/// Cumulative quantities behind a Production entry for one PO line:
/// Sewing completed on or before [productionDate], the Production already
/// recorded, and the resulting available balance.
///
/// `available = sewingQuantity − producedQuantity`
class GetProductionAvailabilityUseCase {
  GetProductionAvailabilityUseCase(
    this._sewingRepository,
    this._productionRepository,
  );
  final ISewingRepository _sewingRepository;
  final IProductionRepository _productionRepository;

  Future<Either<String, ProductionAvailability>> call({
    required String poTagNo,
    required String poNo,
    required String article,
    required String color,
    required DateTime productionDate,
    String? excludeId,
  }) async {
    try {
      final sewing = poNo.isEmpty
          ? await _sewingRepository.getCumulativeSewingQuantity(
              poTagNo: poTagNo,
              upToDate: productionDate,
            )
          : await _sewingRepository.getCumulativeSewingQty(
              poNo: poNo,
              article: article,
              color: color,
            );
      final produced = poNo.isEmpty
          ? await _productionRepository.getCumulativeProductionQuantity(
              poTagNo: poTagNo,
              upToDate: productionDate,
            )
          : await _productionRepository.getCumulativeProductionQty(
              poNo: poNo,
              article: article,
              color: color,
              excludeId: excludeId,
            );
      return Right(
        ProductionAvailability(
          sewingQuantity: sewing,
          producedQuantity: produced,
          availableQuantity: (sewing - produced).clamp(0, sewing).toInt(),
        ),
      );
    } catch (_) {
      return const Left('Unable to load production availability');
    }
  }
}

/// Result of [GetProductionAvailabilityUseCase].
class ProductionAvailability {
  const ProductionAvailability({
    required this.sewingQuantity,
    required this.producedQuantity,
    required this.availableQuantity,
  });
  final int sewingQuantity;
  final int producedQuantity;
  final int availableQuantity;
}
