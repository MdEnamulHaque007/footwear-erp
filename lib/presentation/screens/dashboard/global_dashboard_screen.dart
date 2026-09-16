import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../blocs/dashboard/dashboard_event.dart';
import '../../blocs/dashboard/dashboard_state.dart';
import '../../widgets/app_drawer.dart';
import 'responsive/dashboard_layout.dart';
import 'widgets/sidebar/dashboard_sidebar.dart';
import 'widgets/topbar/dashboard_topbar.dart';

class GlobalDashboardScreen extends StatefulWidget {
  const GlobalDashboardScreen({super.key});
  @override
  State<GlobalDashboardScreen> createState() => _GlobalDashboardScreenState();
}
class _GlobalDashboardScreenState extends State<GlobalDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<DashboardBloc>().add(const DashboardStarted());
      }
    });
  }
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
    final desktop = constraints.maxWidth >= 1200;
    final tablet = constraints.maxWidth >= 768;
    return Scaffold(
      drawer: const AppDrawer(),
      body: Row(children: [
        if (desktop) const SizedBox(width: 260, child: DashboardSidebar()),
        if (!desktop && tablet) const SizedBox(width: 72, child: DashboardSidebar(compact: true)),
        Expanded(child: Column(children: [
          Builder(builder: (scaffoldContext) => DashboardTopbar(onMenu: () => Scaffold.of(scaffoldContext).openDrawer())),
          Expanded(child: BlocBuilder<DashboardBloc, DashboardState>(builder: (context, state) {
            if (state is DashboardInitial || state is DashboardLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is DashboardError) {
              return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(state.message), const SizedBox(height: 12), FilledButton.icon(onPressed: () => context.read<DashboardBloc>().add(const RefreshDashboard()), icon: const Icon(Icons.refresh), label: const Text('Retry'))]));
            }
            return DashboardLayout(state: state as DashboardLoaded);
          })),
        ])),
      ]),
    );
  });
}
