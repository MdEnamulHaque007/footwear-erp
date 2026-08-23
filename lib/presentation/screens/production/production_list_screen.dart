import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/entities/production_entity.dart';
import '../../blocs/production/production_bloc.dart';
import '../../blocs/production/production_event.dart';
import '../../blocs/production/production_state.dart';

class ProductionListScreen extends StatefulWidget {
  const ProductionListScreen({super.key});

  @override
  State<ProductionListScreen> createState() => _ProductionListScreenState();
}

class _ProductionListScreenState extends State<ProductionListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductionBloc>().add(LoadProductionList());
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final bloc = context.read<ProductionBloc>();
      if (bloc.state is ProductionLoaded) {
        bloc.add(LoadMoreProductionList());
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
    appBar: AppBar(title: const Text('Production')),
    floatingActionButton: FloatingActionButton(
      onPressed: () => context.push('/production/new'),
      child: const Icon(Icons.add),
    ),
    body: BlocConsumer<ProductionBloc, ProductionState>(
      listener: (context, state) {
        if (state is ProductionSuccess) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        } else if (state is ProductionError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      buildWhen: (previous, current) =>
          current is! ProductionSuccess && current is! ProductionError,
      builder: (context, state) {
        if (state is ProductionLoading &&
            context.read<ProductionBloc>().state is! ProductionLoaded) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = state is ProductionLoaded
            ? state.items
            : <ProductionEntity>[];

        if (items.isEmpty && state is! ProductionLoading) {
          return const Center(child: Text('No Production Records'));
        }

        return ListView.builder(
          controller: _scrollController,
          itemCount: items.length + (state is ProductionLoading ? 1 : 0),
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
                onPressed: () => context.read<ProductionBloc>().add(
                  DeleteProduction(item.id!),
                ),
              ),
            );
          },
        );
      },
    ),
  );
}
