import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/color_palette.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../blocs/dashboard/dashboard_event.dart';
import '../../blocs/dashboard/dashboard_state.dart';
import '../../routes/route_constants.dart';
import '../../widgets/app_drawer.dart';
import 'widgets/comparison/comparison_animation_widget.dart';
import 'widgets/factory_comparison_chart.dart';
import 'widgets/kpi_grid_widget.dart';
import 'widgets/module_distribution_chart.dart';
import 'widgets/production_trend_chart.dart';
import 'widgets/quick_actions_widget.dart';
import 'widgets/quick_stats_widget.dart';
import 'widgets/recent_activities_widget.dart';
import 'widgets/welcome_header_widget.dart';

/// The dashboard: nine sections assembled from one [DashboardLoaded] snapshot.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<DashboardBloc>().add(DashboardStarted());
    });
  }

  Future<void> _refresh() async {
    context.read<DashboardBloc>().add(RefreshDashboard());
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final role = authState is Authenticated ? authState.user.role : 'viewer';

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        leadingWidth: 96,
        leading: Builder(
          builder: (context) => IconButton(
            tooltip: 'Menu',
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Time-Lapse Report',
            icon: const Icon(Icons.timeline_outlined),
            onPressed: () => context.go(RouteConstants.timelapseDashboard),
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
          if (role == 'admin')
            IconButton(
              tooltip: 'Admin',
              icon: const Icon(Icons.admin_panel_settings),
              onPressed: () => context.go('/admin'),
            ),
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.go(RouteConstants.profile),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) => switch (state) {
          // Partial must precede Loaded: DashboardPartialLoaded extends
          // DashboardLoaded, so the narrower type has to match first.
          DashboardPartialLoaded() => _content(state, warning: state.warning),
          DashboardLoaded() => _content(state),
          DashboardError(:final message) => _ErrorView(
            message: message,
            onRetry: _refresh,
          ),
          DashboardInitial() => const _Skeleton(),
          DashboardLoading() => const _Skeleton(),
        },
      ),
    );
  }

  /// The nine dashboard sections, top to bottom.
  Widget _content(DashboardLoaded state, {String? warning}) => RefreshIndicator(
    onRefresh: _refresh,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final padding = constraints.maxWidth >= 760 ? 32.0 : 16.0;
        final wide = constraints.maxWidth >= 980;
        return ListView(
          padding: EdgeInsets.fromLTRB(padding, 20, padding, 48),
          children: [
            if (warning != null) ...[
              _warningBanner(warning),
              const SizedBox(height: 14),
            ],
            WelcomeHeaderWidget(
              factoryName: state.stats.totalRecords == 0
                  ? ''
                  : '${state.stats.totalRecords} records',
              onRefresh: _refresh,
            ),
            const SizedBox(height: 20),
            _sectionTitle(context, 'Key Metrics'),
            const SizedBox(height: 12),
            KpiGridWidget(stats: state.stats),
            const SizedBox(height: 20),
            const ComparisonAnimationWidget(),
            const SizedBox(height: 20),
            ProductionTrendChart(points: state.trend),
            const SizedBox(height: 20),
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: FactoryComparisonChart(
                      points: state.factoryComparison,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ModuleDistributionChart(
                      points: state.moduleDistribution,
                    ),
                  ),
                ],
              )
            else ...[
              FactoryComparisonChart(points: state.factoryComparison),
              const SizedBox(height: 16),
              ModuleDistributionChart(points: state.moduleDistribution),
            ],
            const SizedBox(height: 20),
            RecentActivitiesWidget(activities: state.activities),
            const SizedBox(height: 20),
            _sectionTitle(context, 'Activity Summary'),
            const SizedBox(height: 12),
            QuickStatsWidget(stats: state.quickStats),
            const SizedBox(height: 20),
            const QuickActionsWidget(),
          ],
        );
      },
    ),
  );

  Widget _sectionTitle(BuildContext context, String title) => Text(
    title,
    style: Theme.of(
      context,
    ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
  );

  /// Non-blocking notice shown when only some panels loaded.
  Widget _warningBanner(String message) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: ColorPalette.warning.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: ColorPalette.warning.withValues(alpha: 0.4)),
    ),
    child: Row(
      children: [
        const Icon(Icons.info_outline, color: ColorPalette.warning, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(message)),
      ],
    ),
  );
}

/// Placeholder tiles shown during the first load.
class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      for (final height in [130.0, 110.0, 150.0, 280.0, 240.0])
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
    ],
  );
}

/// Full-page failure with a retry, shown only when nothing loaded at all.
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, size: 64, color: ColorPalette.error),
          const SizedBox(height: 16),
          Text(
            'Unable to load the dashboard',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    ),
  );
}

