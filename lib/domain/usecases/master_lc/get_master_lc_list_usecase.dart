import 'package:dartz/dartz.dart';
import '../../repositories/i_master_lc_repository.dart';
import '../../../data/models/master_lc/master_lc_model.dart';

class GetMasterLCListUseCase { 
  GetMasterLCListUseCase(this._repository); 
  final IMasterLCRepository _repository; 
  
  Future<Either<String, List<MasterLCModel>>> call({int page = 0, int limit = 20}) => 
    _repository.getMasterLCList(page: page, limit: limit); 
}
