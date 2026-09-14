import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/entities/master_lc_entity.dart';
import '../../blocs/master_lc/master_lc_bloc.dart';
import '../../blocs/master_lc/master_lc_event.dart';
import '../../blocs/master_lc/master_lc_state.dart';
import '../../routes/route_constants.dart';
import '../../widgets/app_drawer.dart';

class MasterLCListScreen extends StatefulWidget {
  const MasterLCListScreen({super.key});

  @override
  State<MasterLCListScreen> createState() => _MasterLCListScreenState();
}

class _MasterLCListScreenState extends State<MasterLCListScreen> {
  final _searchController = TextEditingController();
  final _verticalScroll = ScrollController();
  bool _searching = false;

  /// Guards against firing a second page fetch while one is in flight. The
  /// bloc has its own `_isLoadingMore` guard; this keeps the scroll listener
  /// from spamming events on every frame of a fast fling.
  bool _loadingMore = false;

  /// Set when a page fetch fails, so the scroll listener stops retrying until
  /// the user refreshes or taps Retry.
  bool _loadMoreFailed = false;

  /// The last successfully loaded rows, kept so an error state can still show
  /// them instead of blanking the list.
  List<MasterLCEntity> _lastLoadedItems = const [];

  /// The active search text. Held in state (not read straight off the
  /// controller) so a row-filtered view and the load-more trigger agree on what
  /// is being searched.
  String _searchQuery = '';

  /// True while a search-triggered page pull is already queued for this frame,
  /// so the same click cannot enqueue the fetch twice.
  bool _searchAutoLoadScheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MasterLCBloc>().add(LoadMasterLCList());
    });
    _verticalScroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _verticalScroll.removeListener(_onScroll);
    _verticalScroll.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Fetches the next page once the list is scrolled near the bottom.
  void _onScroll() {
    // A page failed: stay armed-off until the user refreshes, so a broken
    // request cannot re-fire on every scroll frame.
    if (_loadMoreFailed) return;
    if (!_verticalScroll.hasClients) return;
    final position = _verticalScroll.position;
    if (position.pixels < position.maxScrollExtent - 200) return;

    // A filtered view may not be scrollable at all, so keep pulling pages while
    // a search is active until the record is found or the data runs out.
    if (!_maybeAutoLoadForSearch()) return;

    if (_loadingMore) return;
    final state = context.read<MasterLCBloc>().state;
    final hasMore = switch (state) {
      MasterLCLoaded(:final hasMore) => hasMore,
      MasterLCLoadingMore() => false,
      _ => false,
    };
    if (!hasMore) return;
    _loadingMore = true;
    context.read<MasterLCBloc>().add(LoadMoreMasterLC());
  }

  /// While a search is active, keeps fetching pages until either a match is
  /// found or the data is exhausted, so a record on a later page still surfaces
  /// without the user having to scroll a list that cannot scroll.
  ///
  /// Returns true when the list is still scrollable and the normal bottom-edge
  /// trigger should proceed.
  bool _maybeAutoLoadForSearch() {
    if (_searchQuery.trim().isEmpty) return true;
    final state = context.read<MasterLCBloc>().state;
    final hasMore = switch (state) {
      MasterLCLoaded(:final hasMore) => hasMore,
      _ => false,
    };
    if (!hasMore) return false;
    if (_filteredItems(_lastLoadedItems).isNotEmpty) return true;
    if (_loadingMore) return false;
    _loadingMore = true;
    context.read<MasterLCBloc>().add(LoadMoreMasterLC());
    return false;
  }

  /// Kicks off another page fetch so a match sitting on a not-yet-loaded page is
  /// pulled in without requiring a scroll. Only ever called from a post-frame
  /// callback, never inline from a widget callback.
  ///
  /// The chain repeats via the state branch in [build] until a match appears or
  /// the data is exhausted.
  void _loadMoreForSearchIfNeeded() {
    if (!mounted) return;
    if (_searchQuery.trim().isEmpty) return;
    if (_loadMoreFailed) return;
    if (_loadingMore) return;
    final state = context.read<MasterLCBloc>().state;
    final hasMore = switch (state) {
      MasterLCLoaded(:final hasMore) => hasMore,
      _ => false,
    };
    if (!hasMore) return;
    if (_filteredItems(_lastLoadedItems).isNotEmpty) return;
    _loadingMore = true;
    context.read<MasterLCBloc>().add(LoadMoreMasterLC());
  }

  /// Schedules at most one page pull per frame.
  ///
  /// Searching pulls pages in a chain (page 2, then 3, then 4...) until a match
  /// is found. Routing every trigger through a post-frame callback keeps those
  /// state changes out of the current build/notification phase and collapses
  /// duplicate submissions when a listener fires more than once per frame.
  void _scheduleSearchAutoLoad() {
    if (_searchAutoLoadScheduled) return;
    _searchAutoLoadScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchAutoLoadScheduled = false;
      _loadMoreForSearchIfNeeded();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: _searching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search tag, company, project, LC or SC no.',
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  // Update the query and rebuild synchronously. The page-pull
                  // decision is made from the build method (post-frame), never
                  // inline here: this runs inside the TextField's own
                  // notification phase, where dispatching a bloc event can
                  // rebuild this subtree mid-notification.
                  setState(() => _searchQuery = value);
                },
              )
            : const Text('Master LC List'),
        // Two controls in the leading slot: back out of this screen, and open
        // the app drawer for lateral navigation.
        leadingWidth: 96,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Back',
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  context.go(RouteConstants.dashboard);
                }
              },
            ),
            Builder(
              builder: (drawerContext) => IconButton(
                icon: const Icon(Icons.menu),
                tooltip: 'Menu',
                onPressed: () => Scaffold.of(drawerContext).openDrawer(),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: _searching ? 'Close search' : 'Search',
            icon: Icon(_searching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _searching = !_searching;
                if (!_searching) {
                  _searchController.clear();
                  _searchQuery = '';
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              // Re-arm pagination after a failed page.
              _loadMoreFailed = false;
              context.read<MasterLCBloc>().add(LoadMasterLCList());
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New Master LC',
            onPressed: () => context.push('/master-lc/new'),
          ),
        ],
      ),
      body: BlocConsumer<MasterLCBloc, MasterLCState>(
        listener: (context, state) {
          if (state is MasterLCSuccess) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          } else if (state is MasterLCError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          if (state is MasterLCLoading &&
              context.read<MasterLCBloc>().state is! MasterLCLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is MasterLCError) {
            _loadingMore = false;
            _loadMoreFailed = true;
            // Keep the rows already loaded instead of blanking the screen.
            if (_lastLoadedItems.isNotEmpty) {
              return _buildExcelTable(_lastLoadedItems);
            }
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${state.message}'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<MasterLCBloc>().add(LoadMasterLCList()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (state is MasterLCLoaded) {
            _loadingMore = false;
            _loadMoreFailed = false;
            _lastLoadedItems = state.items;
            // Search active but nothing matched yet: keep pulling pages so a
            // record on a later page still surfaces.
            if (_searchQuery.trim().isNotEmpty &&
                state.hasMore &&
                _filteredItems(state.items).isEmpty) {
              _scheduleSearchAutoLoad();
            }
            return _buildExcelTable(
              _filteredItems(state.items),
              hasMore: state.hasMore,
            );
          }
          if (state is MasterLCLoadingMore) {
            _lastLoadedItems = state.items;
            return _buildExcelTable(
              _filteredItems(state.items),
              hasMore: false,
              loadingMore: true,
            );
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/master-lc/new'),
        child: const Icon(Icons.add),
      ),
    );
  }

  List<MasterLCEntity> _filteredItems(List<MasterLCEntity> items) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return items;
    // Runs over every row loaded so far, not just the first page, so records
    // pulled in by Load More are searchable too.
    //
    // Each field is coerced to a String first. The entity types these as
    // non-nullable `String`, but a legacy Firestore document can still hand back
    // a non-string (or a JS `undefined` on web), and calling `.toLowerCase()`
    // on that throws `NoSuchMethodError` — which surfaces as
    // "Cannot read properties of undefined" under dart2js.
    return items.where((item) {
      return _contains(item.tagNo, query) ||
          _contains(item.company, query) ||
          _contains(item.project, query) ||
          _contains(item.lcNo, query) ||
          _contains(item.scNo, query) ||
          _contains(item.ttNo, query);
    }).toList();
  }

  /// Case-insensitive substring test that tolerates a non-string [value].
  static bool _contains(Object? value, String lowerCaseQuery) =>
      (value?.toString() ?? '').toLowerCase().contains(lowerCaseQuery);

  /// Renders a possibly non-string Firestore value as display text, falling back
  /// to [fallback] when it is null or blank.
  static String _text(Object? value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  Widget _buildExcelTable(
    List<MasterLCEntity> items, {
    bool hasMore = false,
    bool loadingMore = false,
  }) {
    if (items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.table_chart_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No Master LC records found',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: Scrollbar(
            controller: _verticalScroll,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _verticalScroll,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 20,
                  horizontalMargin: 16,
                  headingRowColor: WidgetStateProperty.all(
                    Colors.blueGrey.shade50,
                  ),
                  border: TableBorder.all(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                  columns: const [
                    DataColumn(
                      label: Text(
                        'SL',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Tag No',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Project',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Company',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'LC No',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'SC No',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'TT No',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Qty',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Value (\$)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Action',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  rows: items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return DataRow(
                      color: WidgetStateProperty.resolveWith<Color?>(
                        (states) =>
                            index.isEven ? Colors.grey.shade50 : Colors.white,
                      ),
                      onSelectChanged: item.id == null
                          ? null
                          : (_) => context.push(
                              '/master-lc/detail/${item.id}',
                              extra: item,
                            ),
                      cells: [
                        // SRS Rule 1: show the auto-generated stored Sl., not the row
                        // position, so the list matches the detail view.
                        DataCell(Text(item.sl.toString())),
                        DataCell(
                          InkWell(
                            onTap: () => context.push(
                              '/master-lc/detail/${item.id}',
                              extra: item,
                            ),
                            child: Text(
                              _text(item.tagNo),
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        DataCell(Text(_text(item.project))),
                        DataCell(Text(_text(item.company))),
                        DataCell(Text(_text(item.lcNo, fallback: '-'))),
                        DataCell(Text(_text(item.scNo, fallback: '-'))),
                        DataCell(Text(_text(item.ttNo, fallback: '-'))),
                        DataCell(Text(_formatQuantity(item.masterLcQuantity))),
                        DataCell(Text(_formatValue(item.masterLcValue))),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.visibility,
                                  size: 18,
                                  color: Colors.blue,
                                ),
                                tooltip: 'View Details',
                                onPressed: () => context.push(
                                  '/master-lc/detail/${item.id}',
                                  extra: item,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  size: 18,
                                  color: Colors.blue,
                                ),
                                tooltip: 'Edit',
                                onPressed: item.id == null
                                    ? null
                                    : () => context.push(
                                        '/master-lc/edit/${item.id}',
                                        extra: item,
                                      ),
                              ),
                              if (item.id != null)
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    size: 18,
                                    color: Colors.red,
                                  ),
                                  tooltip: 'Delete',
                                  onPressed: item.id == null
                                      ? null
                                      : () => _showDeleteDialog(
                                          context,
                                          item.id!,
                                          item.tagNo,
                                        ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
        _loadMoreFooter(hasMore: hasMore, loadingMore: loadingMore),
      ],
    );
  }

  /// Footer shown under the table: a spinner while a page is in flight, a hint
  /// when more rows are available, and nothing once the list is exhausted.
  Widget _loadMoreFooter({required bool hasMore, required bool loadingMore}) {
    if (loadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Loading more...'),
          ],
        ),
      );
    }
    if (hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Scroll down to load more',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: () {
                if (_loadingMore) return;
                _loadingMore = true;
                context.read<MasterLCBloc>().add(LoadMoreMasterLC());
              },
              child: const Text('Load More'),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  String _formatQuantity(int value) => NumberFormat('#,##0').format(value);
  String _formatValue(double value) =>
      NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(value);

  void _showDeleteDialog(BuildContext context, String id, String tagNo) {
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Master LC'),
        content: Text('Are you sure you want to delete Master LC "$tagNo"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<MasterLCBloc>().add(DeleteMasterLC(id));
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
