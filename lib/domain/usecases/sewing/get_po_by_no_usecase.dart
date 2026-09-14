import 'package:dartz/dartz.dart';
import '../../entities/po_entity.dart';
import '../../repositories/i_sewing_repository.dart';

/// Loads the Purchase Order behind a PO No so the form can auto-fill Tag No,
/// Company, Project and the Article/Color cascading dropdowns.
class GetSewingPOByNoUseCase {
  GetSewingPOByNoUseCase(this._repository);
  final ISewingRepository _repository;

  Future<Either<String, POEntity?>> call(String poNo) async {
    try {
      return await _repository.getPOByNo(poNo);
    } catch (_) {
      return const Left('Unable to load purchase order');
    }
  }
}
