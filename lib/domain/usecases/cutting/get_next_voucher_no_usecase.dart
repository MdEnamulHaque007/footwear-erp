import 'package:dartz/dartz.dart';

import '../../repositories/i_cutting_repository.dart';

class GetNextVoucherNoUseCase {
  GetNextVoucherNoUseCase(this._repository);

  final ICuttingRepository _repository;

  Future<Either<String, String>> call(DateTime date) {
    return _repository.getNextVoucherNo(date);
  }
}
