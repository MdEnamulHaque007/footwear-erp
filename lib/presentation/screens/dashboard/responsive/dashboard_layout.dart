import 'package:flutter/material.dart';
import '../widgets/activities/audit_log_widget.dart';
import '../widgets/charts/department_performance_chart.dart';
import '../widgets/charts/timelapse_production_chart.dart';
import '../widgets/kpi/kpi_cards_row.dart';
import '../widgets/tables/production_efficiency_table.dart';
import '../widgets/tables/warehouse_report_table.dart';
import '../../../blocs/dashboard/dashboard_state.dart';

class DashboardLayout extends StatelessWidget {
  const DashboardLayout({super.key, required this.state});
  final DashboardLoaded state;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= 1100;
      final padding = constraints.maxWidth >= 760 ? 28.0 : 16.0;
      final warning = state is DashboardPartialLoaded
          ? (state as DashboardPartialLoaded).warning
          : '';
      final charts = [
        Expanded(flex: 3, child: TimelapseProductionChart(points: state.trend)),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: DepartmentPerformanceChart(points: state.trend),
        ),
      ];
      final lower = [
        Expanded(
          child: ProductionEfficiencyTable(factories: state.factoryComparison),
        ),
        const SizedBox(width: 16),
        Expanded(child: AuditLogWidget(activities: state.activities)),
      ];
      return ListView(
        padding: EdgeInsets.all(padding),
        children: [
          if (warning.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: MaterialBanner(
                content: Text(warning),
                actions: const [SizedBox.shrink()],
              ),
            ),
          KpiCardsRow(stats: state.stats),
          const SizedBox(height: 20),
          if (wide)
            SizedBox(
              height: 345,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: charts,
              ),
            )
          else ...[
            TimelapseProductionChart(points: state.trend),
            const SizedBox(height: 16),
            DepartmentPerformanceChart(points: state.trend),
          ],
          const SizedBox(height: 20),
          if (wide)
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: lower)
          else ...[
            ProductionEfficiencyTable(factories: state.factoryComparison),
            const SizedBox(height: 16),
            AuditLogWidget(activities: state.activities),
          ],
          const SizedBox(height: 20),
          WarehouseReportTable(stats: state.stats),
        ],
      );
    },
  );
}
