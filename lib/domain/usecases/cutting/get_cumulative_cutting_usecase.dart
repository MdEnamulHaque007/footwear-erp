import '../../repositories/i_cutting_repository.dart';

class GetCumulativeCuttingUseCase {
  GetCumulativeCuttingUseCase(this._repository);
  final ICuttingRepository _repository;
  Future<int> call({
    required String poNo,
    required String article,
    required String color,
    String? excludingId,
  }) => _repository.getCumulativeCuttingQuantityByLine(
    poNo: poNo,
    article: article,
    color: color,
    excludingId: excludingId,
  );
}
