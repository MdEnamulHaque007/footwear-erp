import 'package:dartz/dartz.dart';
import '../../repositories/i_master_lc_repository.dart';

class DeleteMasterLCUseCase { 
  DeleteMasterLCUseCase(this._repository); 
  final IMasterLCRepository _repository; 
  
  Future<Either<String, void>> call(String id) => _repository.delete(id); 
}
