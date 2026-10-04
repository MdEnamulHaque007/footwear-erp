import 'package:dartz/dartz.dart';

import '../../core/failure.dart';
import '../../../../data/repositories/master_lc_repository.dart';
import '../../../../data/repositories/po_repository.dart';
import '../../../../domain/entities/po_entity.dart';
import '../../data/models/cutting_model.dart';
import '../../data/repositories/cutting_repository.dart';

class CreateManualCuttingUseCase {
  CreateManualCuttingUseCase({
    required CuttingRepository cuttingRepository,
    required PORepository poRepository,
    required MasterLCRepository masterLCRepository,
  })  : _cuttingRepository = cuttingRepository,
        _poRepository = poRepository,
        _masterLCRepository = masterLCRepository;

  final CuttingRepository _cuttingRepository;
  final PORepository _poRepository;
  final MasterLCRepository _masterLCRepository;

  Future<Either<Failure, Cutting>> resolve({
    required DateTime cuttingDate,
    required String voucherNo,
    required String factoryName,
    required String poNo,
    required String article,
    required String color,
    required int cuttingQuantity,
    required String entryPerson,
  }) async {
    if (cuttingQuantity <= 0) {
      return const Left(Failure('Cutting Quantity must be greater than 0.'));
    }
    if (poNo.trim().isEmpty) {
      return const Left(Failure('PO No is required.'));
    }
    if (article.trim().isEmpty) {
      return const Left(Failure('Article No is required.'));
    }
    if (color.trim().isEmpty) {
      return const Left(Failure('Color is required.'));
    }

    final poResult = await _poRepository.getPOByNo(poNo.trim());
    return poResult.fold(
      (error) => Left(Failure(error)),
      (po) async {
        if (po == null) {
          return const Left(Failure('PO No was not found in Purchase Orders.'));
        }

        final normalizedArticle = article.trim().toLowerCase();
        final normalizedColor = color.trim().toLowerCase();

        POLineItemEntity? matchingLine;
        for (final line in po.effectiveLineItems) {
          if (line.article.trim().toLowerCase() == normalizedArticle &&
              line.color.trim().toLowerCase() == normalizedColor) {
            matchingLine = line;
            break;
          }
        }

        if (matchingLine == null) {
          return Left(
            Failure(
              'Article "' +
                  article +
                  '" + Color "' +
                  color +
                  '" was not found in PO ' +
                  po.poNo +
                  '.',
            ),
          );
        }

        var company = po.company.trim();
        var project = po.project.trim();

        if ((company.isEmpty || project.isEmpty) && po.tagNo.trim().isNotEmpty) {
          final masterResult = await _masterLCRepository.byTag(po.tagNo.trim());
          masterResult.fold(
            (_) {},
            (master) {
              if (master != null) {
                if (company.isEmpty) company = master.company.trim();
                if (project.isEmpty) project = master.project.trim();
              }
            },
          );
        }

        final voucher = voucherNo.trim().isEmpty
            ? await _cuttingRepository.getNextVoucherNo(cuttingDate)
            : Right<Failure, String>(voucherNo.trim());

        return voucher.fold(
          (failure) => Left(failure),
          (resolvedVoucher) {
            final now = DateTime.now();
            return Right(
              Cutting(
                voucherNo: resolvedVoucher,
                cuttingDate: cuttingDate,
                factoryName: factoryName.trim(),
                poNo: po.poNo.trim(),
                article: matchingLine!.article.trim(),
                color: matchingLine.color.trim(),
                cuttingQuantity: cuttingQuantity,
                entryPerson: entryPerson.trim(),
                tagNo: po.tagNo.trim(),
                company: company,
                project: project,
                poQuantity: matchingLine.poQuantity,
                source: 'manual',
                syncStatus: 'synced',
                createdAt: now,
                updatedAt: now,
              ),
            );
          },
        );
      },
    );
  }

  Future<Either<Failure, void>> create({
    required DateTime cuttingDate,
    required String voucherNo,
    required String factoryName,
    required String poNo,
    required String article,
    required String color,
    required int cuttingQuantity,
    required String entryPerson,
  }) async {
    final resolved = await resolve(
      cuttingDate: cuttingDate,
      voucherNo: voucherNo,
      factoryName: factoryName,
      poNo: poNo,
      article: article,
      color: color,
      cuttingQuantity: cuttingQuantity,
      entryPerson: entryPerson,
    );

    return resolved.fold(
      (failure) => Left(failure),
      (cutting) async {
        try {
          await _cuttingRepository.create(cutting);
          return const Right(null);
        } on Failure catch (e) {
          return Left(e);
        } catch (e) {
          return Left(Failure(e.toString()));
        }
      },
    );
  }
}
