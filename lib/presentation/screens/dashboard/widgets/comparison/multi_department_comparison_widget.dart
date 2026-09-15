import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../domain/entities/dashboard/comparison_item_entity.dart';
import '../../../../../domain/entities/dashboard/department_option_entity.dart';
import '../../../../blocs/dashboard/dashboard_bloc.dart';
import '../../../../blocs/dashboard/dashboard_event.dart';
import '../../../../blocs/dashboard/dashboard_state.dart';
import 'department_card_widget.dart';
import 'multi_department_chart_widget.dart';

class MultiDepartmentComparisonWidget extends StatefulWidget {
  const MultiDepartmentComparisonWidget({super.key});

  @override
  State<MultiDepartmentComparisonWidget> createState() =>
      _MultiDepartmentComparisonWidgetState();
}

class _MultiDepartmentComparisonWidgetState
    extends State<MultiDepartmentComparisonWidget> {
  late List<ComparisonItem> _items;
  var _nextId = 3;
  var _hasRequestedComparison = false;

  @override
  void initState() {
    super.initState();
    final range = DateTimeRange(
      start: DateTime(2026, 1, 1),
      end: DateTime(2026, 6, 30),
    );
    _items = [
      ComparisonItem(
        id: 'comparison-1',
        department: DepartmentOption.all[2],
        fromDate: range.start,
        toDate: range.end,
      ),
      ComparisonItem(
        id: 'comparison-2',
        department: DepartmentOption.all[3],
        fromDate: range.start,
        toDate: range.end,
      ),
    ];
  }

  void _load() {
    setState(() => _hasRequestedComparison = true);
    context.read<DashboardBloc>().add(LoadComparisonData(items: _items));
  }

  void _update(int index, ComparisonItem item) {
    if (_items.asMap().entries.any(
      (entry) =>
          entry.key != index && entry.value.department == item.department,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Each department can be selected once.')),
      );
      return;
    }
    setState(() {
      _items[index] = item;
      _hasRequestedComparison = false;
    });
  }

  void _add() {
    if (_items.length >= DepartmentOption.all.length) return;
    final selected = _items.map((item) => item.department).toSet();
    final department = DepartmentOption.all.firstWhere(
      (option) => !selected.contains(option),
    );
    setState(() {
      _items.add(
        ComparisonItem(
          id: 'comparison-${_nextId++}',
          department: department,
          fromDate: DateTime(2026, 1, 1),
          toDate: DateTime(2026, 6, 30),
        ),
      );
      _hasRequestedComparison = false;
    });
  }

  void _reset() {
    final range = DateTimeRange(
      start: DateTime(2026, 1, 1),
      end: DateTime(2026, 6, 30),
    );
    setState(() {
      _items = [
        ComparisonItem(
          id: 'comparison-1',
          department: DepartmentOption.all[2],
          fromDate: range.start,
          toDate: range.end,
        ),
        ComparisonItem(
          id: 'comparison-2',
          department: DepartmentOption.all[3],
          fromDate: range.start,
          toDate: range.end,
        ),
      ];
      _nextId = 3;
      _hasRequestedComparison = false;
    });
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Department Comparison',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _items.length >= 7 ? null : _add,
                icon: const Icon(Icons.add),
                label: const Text('Add Department'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Select one to seven departments. Each card has its own dates and chart.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth < 720
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 14) / 2;
              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  for (var index = 0; index < _items.length; index++)
                    SizedBox(
                      width: width,
                      child: DepartmentCardWidget(
                        index: index,
                        item: _items[index],
                        canRemove: _items.length > 1,
                        onChanged: (item) => _update(index, item),
                        onRemove: () => setState(() {
                          _items.removeAt(index);
                          _hasRequestedComparison = false;
                        }),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.play_arrow),
                label: const Text('View'),
              ),
              OutlinedButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.restart_alt),
                label: const Text('Reset'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          BlocBuilder<DashboardBloc, DashboardState>(
            builder: (context, state) {
              if (!_hasRequestedComparison) {
                return const SizedBox(
                  height: 120,
                  child: Center(
                    child: Text('Ready. Select departments and press View.'),
                  ),
                );
              }
              if (state is! DashboardLoaded) {
                return const SizedBox(
                  height: 160,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (state.comparisonResults.isEmpty) {
                return const SizedBox(
                  height: 120,
                  child: Center(
                    child: Text('Ready. Select departments and press View.'),
                  ),
                );
              }
              return MultiDepartmentChartWidget(
                results: state.comparisonResults,
              );
            },
          ),
        ],
      ),
    ),
  );
}
