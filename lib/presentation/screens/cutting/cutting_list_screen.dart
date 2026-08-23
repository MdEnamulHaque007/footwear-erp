import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/entities/cutting_entity.dart';
import '../../blocs/cutting/cutting_bloc.dart';
import '../../blocs/cutting/cutting_event.dart';
import '../../blocs/cutting/cutting_state.dart';

class CuttingListScreen extends StatefulWidget {
  const CuttingListScreen({super.key});

  @override
  State<CuttingListScreen> createState() => _CuttingListScreenState();
}

class _CuttingListScreenState extends State<CuttingListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CuttingBloc>().add(LoadCuttingList());
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final bloc = context.read<CuttingBloc>();
      if (bloc.state is CuttingLoaded) {
        bloc.add(LoadMoreCuttingList());
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
    appBar: AppBar(title: const Text('Cutting')),
    floatingActionButton: FloatingActionButton(
      onPressed: () => context.push('/cutting/new'),
      child: const Icon(Icons.add),
    ),
    body: BlocConsumer<CuttingBloc, CuttingState>(
      listener: (context, state) {
        if (state is CuttingSuccess) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        } else if (state is CuttingError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      buildWhen: (previous, current) =>
          current is! CuttingSuccess && current is! CuttingError,
      builder: (context, state) {
        if (state is CuttingLoading &&
            context.read<CuttingBloc>().state is! CuttingLoaded) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = state is CuttingLoaded ? state.items : <CuttingEntity>[];

        if (items.isEmpty && state is! CuttingLoading) {
          return const Center(child: Text('No Cutting Records'));
        }

        return ListView.builder(
          controller: _scrollController,
          itemCount: items.length + (state is CuttingLoading ? 1 : 0),
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
                    context.read<CuttingBloc>().add(DeleteCutting(item.id!)),
              ),
            );
          },
        );
      },
    ),
  );
}
