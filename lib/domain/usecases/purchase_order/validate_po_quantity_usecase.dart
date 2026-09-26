/// ============================================================================
/// ফাইল: lib/domain/usecases/purchase_order/validate_po_quantity_usecase.dart
/// স্তর: Domain Use Case | মডিউল: Purchase Order
/// উদ্দেশ্য: Purchase Order মডিউলের একটি নির্দিষ্ট business operation ও validation flow পরিচালনা করে।
/// প্রধান অংশ: POAvailability, ValidatePOQuantityUseCase
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import '../../entities/master_lc_entity.dart';
import '../../entities/po_entity.dart';
import '../../repositories/i_po_repository.dart';
import '../../repositories/i_master_lc_repository.dart';

class POAvailability {
  const POAvailability({
    required this.quantity,
    required this.value,
    required this.masterQuantity,
    required this.masterValue,
  });
  final int quantity;
  final double value;
  final int masterQuantity;
  final double masterValue;
  int get remainingQuantity => masterQuantity - quantity;
  double get remainingValue => masterValue - value;
}

class ValidatePOQuantityUseCase {
  ValidatePOQuantityUseCase(this._repository, [this._masterRepository]);
  final IPORepository _repository;
  final IMasterLCRepository? _masterRepository;

  Future<String?> validateCandidate(POEntity candidate) async {
    final masterResult = await _masterRepository?.byTag(candidate.tagNo);
    if (masterResult == null) {
      return 'Unable to validate Master LC limits';
    }
    String? lookupError;
    MasterLCEntity? master;
    masterResult.fold(
      (error) => lookupError = error,
      (value) => master = value,
    );
    if (lookupError != null) return lookupError;
    if (master == null) return 'Master LC not found for tag ${candidate.tagNo}';
    final result = await call(master!, candidate);
    if (result == null ||
        result == 'Unable to validate Master LC limits' ||
        result.startsWith('Master LC')) {
      return result;
    }
    final available = await availability(candidate);
    if (available == null) return result;
    if (result.startsWith('PO quantity')) {
      return 'PO quantity exceeds remaining Master LC quantity. '
          'Available: ${available.remainingQuantity}';
    }
    return 'PO value exceeds remaining Master LC value. '
        'Available: ${available.remainingValue.toStringAsFixed(2)}';
  }

  Future<POAvailability?> availability(POEntity candidate) async {
    final masterResult = await _masterRepository?.byTag(candidate.tagNo);
    if (masterResult == null) return null;
    return masterResult.fold(
      (_) => null,
      (master) async {
        if (master == null) return null;
        final ordersResult = await _repository.byTag(candidate.tagNo);
        return ordersResult.fold(
          (_) => null,
          (orders) {
            final existing = orders
                .where((po) => po.id != candidate.id)
                .fold(
                  const POAvailability(
                    quantity: 0,
                    value: 0,
                    masterQuantity: 0,
                    masterValue: 0,
                  ),
                  (total, po) => POAvailability(
                    quantity: total.quantity + po.totalQuantity,
                    value: total.value + po.totalValue,
                    masterQuantity: master.masterLcQuantity,
                    masterValue: master.masterLcValue,
                  ),
                );
            return POAvailability(
              quantity: existing.quantity,
              value: existing.value,
              masterQuantity: master.masterLcQuantity,
              masterValue: master.masterLcValue,
            );
          },
        );
      },
    );
  }

  Future<String?> call(MasterLCEntity master, POEntity candidate) async {
    final orders = (await _repository.byTag(
      candidate.tagNo,
    )).fold<List<POEntity>>((_) => const [], (list) => list);
    final quantity =
        orders
            .where((po) => po.id != candidate.id)
            .fold<int>(0, (sum, po) => sum + po.totalQuantity) +
        candidate.totalQuantity;
    final value =
        orders
            .where((po) => po.id != candidate.id)
            .fold<double>(0, (sum, po) => sum + po.totalValue) +
        candidate.totalValue;
    if (quantity > master.masterLcQuantity) {
      return 'PO quantity exceeds available Master LC quantity';
    }
    if (value > master.masterLcValue) {
      return 'PO value exceeds available Master LC value';
    }
    return null;
  }
}
