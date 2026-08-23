import '../../entities/master_lc_entity.dart';
import '../../entities/po_entity.dart';
import '../../repositories/i_po_repository.dart';

class ValidatePOQuantityUseCase {
  ValidatePOQuantityUseCase(this._repository);
  final IPORepository _repository;
  Future<String?> call(MasterLCEntity master, POEntity candidate) async {
    final orders = (await _repository.byTag(candidate.tagNo))
        .fold<List<POEntity>>((_) => const [], (list) => list);
    final quantity =
        orders
            .where((po) => po.id != candidate.id)
            .fold<int>(0, (sum, po) => sum + po.poQuantity) +
        candidate.poQuantity;
    final value =
        orders
            .where((po) => po.id != candidate.id)
            .fold<double>(0, (sum, po) => sum + po.poValue) +
        candidate.poValue;
    if (quantity > master.masterLcQuantity) {
      return 'PO quantity exceeds available Master LC quantity';
    }
    if (value > master.masterLcValue) {
      return 'PO value exceeds available Master LC value';
    }
    return null;
  }
}
