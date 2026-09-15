import 'package:equatable/equatable.dart';

import '../../../domain/entities/reports/warehouse_report_entity.dart';

sealed class WarehouseReportState extends Equatable {
  const WarehouseReportState();

  @override
  List<Object?> get props => const [];
}

class WarehouseReportInitial extends WarehouseReportState {
  const WarehouseReportInitial();
}

class WarehouseReportLoading extends WarehouseReportState {
  const WarehouseReportLoading();
}

class WarehouseReportLoaded extends WarehouseReportState {
  const WarehouseReportLoaded(this.result);

  final WarehouseReportResult result;

  @override
  List<Object?> get props => [result];
}

class WarehouseReportError extends WarehouseReportState {
  const WarehouseReportError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class WarehouseReportExported extends WarehouseReportState {
  const WarehouseReportExported(this.message, this.result);

  final String message;
  final WarehouseReportResult result;

  @override
  List<Object?> get props => [message, result];
}
