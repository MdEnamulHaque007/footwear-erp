import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../routes/route_constants.dart';
import '../../widgets/app_drawer.dart';
import 'widgets/welcome_header_widget.dart';

/// The dashboard: nine sections assembled from one [DashboardLoaded] snapshot.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Dashboard'),
        leading: Builder(
          builder: (context) => IconButton(
            tooltip: 'Menu',
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/settings/notifications'),
          ),
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push(RouteConstants.profile),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => ListView(
          padding: EdgeInsets.fromLTRB(
            constraints.maxWidth >= 760 ? 32 : 16,
            20,
            constraints.maxWidth >= 760 ? 32 : 16,
            48,
          ),
          children: [
            const WelcomeHeaderWidget(),
            const SizedBox(height: 24),
            Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => context.push(RouteConstants.timelapseDashboard),
                child: const Padding(
                  padding: EdgeInsets.all(24),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        child: Icon(Icons.movie_creation_outlined, size: 30),
                      ),
                      SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '🎬 Time-Lapse Report',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text('Watch your production data come alive'),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, size: 18),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

  /* Legacy dashboard sections intentionally disabled.
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
            if (warning?.isNotEmpty == true) ...[
              _warningBanner(warning!),
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
            RepaintBoundary(child: KpiGridWidget(stats: state.stats)),
            const SizedBox(height: 20),
            const RepaintBoundary(child: ComparisonAnimationWidget()),
            const SizedBox(height: 20),
            RepaintBoundary(child: ProductionTrendChart(points: state.trend)),
            const SizedBox(height: 20),
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: RepaintBoundary(
                      child: FactoryComparisonChart(
                        points: state.factoryComparison,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: RepaintBoundary(
                      child: ModuleDistributionChart(
                        points: state.moduleDistribution,
                      ),
                    ),
                  ),
                ],
              )
            else ...[
              RepaintBoundary(
                child: FactoryComparisonChart(points: state.factoryComparison),
              ),
              const SizedBox(height: 16),
              RepaintBoundary(
                child: ModuleDistributionChart(
                  points: state.moduleDistribution,
                ),
              ),
            ],
            const SizedBox(height: 20),
            RepaintBoundary(
              child: RecentActivitiesWidget(activities: state.activities),
            ),
            const SizedBox(height: 20),
            _sectionTitle(context, 'Activity Summary'),
            const SizedBox(height: 12),
            RepaintBoundary(child: QuickStatsWidget(stats: state.quickStats)),
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
*/
