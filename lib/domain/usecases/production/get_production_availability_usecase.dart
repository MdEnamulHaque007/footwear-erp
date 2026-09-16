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
