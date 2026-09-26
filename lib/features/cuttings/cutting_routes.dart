import 'package:go_router/go_router.dart';

import 'data/models/cutting_model.dart';
import 'presentation/screens/cutting_detail_screen.dart';
import 'presentation/screens/cutting_form_screen.dart';
import 'presentation/screens/cutting_list_screen.dart';

final List<RouteBase> cuttingRoutes = [
  GoRoute(
    path: '/cuttings',
    builder: (context, state) => const CuttingListScreen(),
  ),
  GoRoute(
    path: '/cuttings/new',
    builder: (context, state) => const CuttingFormScreen(),
  ),
  GoRoute(
    path: '/cuttings/:docId',
    builder: (context, state) => CuttingDetailScreen(
      docId: state.pathParameters['docId']!,
    ),
  ),
  GoRoute(
    path: '/cuttings/:docId/edit',
    builder: (context, state) => CuttingFormScreen(
      initialCutting: state.extra as Cutting?,
      isEdit: true,
    ),
  ),
];
