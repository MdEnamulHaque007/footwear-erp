import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/entities/issue_entity.dart';
import '../../blocs/issue/issue_bloc.dart';
import '../../blocs/issue/issue_event.dart';
import '../../blocs/issue/issue_state.dart';

class IssueListScreen extends StatefulWidget {
  const IssueListScreen({super.key});

  @override
  State<IssueListScreen> createState() => _IssueListScreenState();
}

class _IssueListScreenState extends State<IssueListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IssueBloc>().add(LoadIssueList());
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final bloc = context.read<IssueBloc>();
      if (bloc.state is IssueLoaded) {
        bloc.add(LoadMoreIssueList());
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Issue')),
    floatingActionButton: FloatingActionButton(
      onPressed: () => context.push('/issue/new'),
      child: const Icon(Icons.add),
    ),
    body: BlocConsumer<IssueBloc, IssueState>(
      listener: (context, state) {
        if (state is IssueSuccess) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        } else if (state is IssueError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      buildWhen: (previous, current) =>
          current is! IssueSuccess && current is! IssueError,
      builder: (context, state) {
        if (state is IssueLoading &&
            context.read<IssueBloc>().state is! IssueLoaded) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = state is IssueLoaded ? state.items : <IssueEntity>[];

        if (items.isEmpty && state is! IssueLoading) {
          return const Center(child: Text('No Issue Records'));
        }

        return ListView.builder(
          controller: _scrollController,
          itemCount: items.length + (state is IssueLoading ? 1 : 0),
          itemBuilder: (_, index) {
            if (index == items.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            final item = items[index];
            return ListTile(
              title: Text(item.voucherNo),
              subtitle: Text('PO: ${item.poTagNo} | Qty: ${item.quantity}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () =>
                    context.read<IssueBloc>().add(DeleteIssue(item.id!)),
              ),
            );
          },
        );
      },
    ),
  );
}
