import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/entities/po_entity.dart';
import '../../blocs/purchase_order/po_bloc.dart';
import '../../blocs/purchase_order/po_event.dart';
import '../../blocs/purchase_order/po_state.dart';

class POListScreen extends StatefulWidget {
  const POListScreen({super.key});

  @override
  State<POListScreen> createState() => _POListScreenState();
}

class _POListScreenState extends State<POListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<POBloc>().add(LoadPOList());
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final bloc = context.read<POBloc>();
      if (bloc.state is POLoaded) {
        bloc.add(LoadMorePOList());
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
    appBar: AppBar(title: const Text('Purchase Orders')),
    floatingActionButton: FloatingActionButton(
      onPressed: () => context.push('/purchase-orders/new'),
      child: const Icon(Icons.add),
    ),
    body: BlocConsumer<POBloc, POState>(
      listener: (context, state) {
        if (state is POSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        } else if (state is POError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      buildWhen: (previous, current) => current is! POSuccess && current is! POError,
      builder: (context, state) {
        if (state is POLoading && context.read<POBloc>().state is! POLoaded) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final items = state is POLoaded ? state.items : <POEntity>[];
        
        if (items.isEmpty && state is! POLoading) {
          return const Center(child: Text('No Purchase Orders'));
        }
        
        return ListView.builder(
          controller: _scrollController,
          itemCount: items.length + (state is POLoading ? 1 : 0),
          itemBuilder: (_, index) {
            if (index == items.length) {
              return const Center(child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ));
            }
            final item = items[index];
            return ListTile(
              title: Text(item.poNo),
              subtitle: Text(
                '${item.tagNo} | ${item.article} | Qty: ${item.poQuantity}',
              ),
              trailing: Text(item.poValue.toStringAsFixed(2)),
            );
          },
        );
      },
    ),
  );
}
