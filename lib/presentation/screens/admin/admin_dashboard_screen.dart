import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../blocs/dashboard/dashboard_event.dart';
import '../../blocs/dashboard/dashboard_state.dart';
import '../../widgets/admin_sidebar_widget.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GetIt.I<DashboardBloc>()..add(LoadDashboardStats()),
      child: Scaffold(
        appBar: AppBar(title: const Text('Admin Dashboard')),
        drawer: const AdminSidebarWidget(),
        body: BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, state) {
            if (state is DashboardLoading || state is DashboardInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is DashboardError) {
              return Center(child: Text('Error: ${state.message}'));
            }
            if (state is DashboardLoaded) {
              return GridView.count(
                crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 4 : 2,
                padding: const EdgeInsets.all(24),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _card(
                    'Total users',
                    '${state.stats.userCount}',
                    Icons.people,
                  ),
                  _card(
                    'Active users',
                    '${state.stats.activeUserCount}',
                    Icons.check_circle,
                  ),
                  _card('Recent activities', 'Audit log', Icons.history),
                  _card(
                    'Total records',
                    '${state.stats.totalRecords}',
                    Icons.inventory_2,
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _card(String title, String value, IconData icon) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon),
          const Spacer(),
          Text(title),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    ),
  );
}
