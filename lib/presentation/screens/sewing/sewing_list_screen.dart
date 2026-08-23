import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/entities/sewing_entity.dart';
import '../../blocs/sewing/sewing_bloc.dart';
import '../../blocs/sewing/sewing_event.dart';
import '../../blocs/sewing/sewing_state.dart';

class SewingListScreen extends StatefulWidget {
  const SewingListScreen({super.key});

  @override
  State<SewingListScreen> createState() => _SewingListScreenState();
}

class _SewingListScreenState extends State<SewingListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SewingBloc>().add(LoadSewingList());
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final bloc = context.read<SewingBloc>();
      if (bloc.state is SewingLoaded) {
        bloc.add(LoadMoreSewingList());
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
    appBar: AppBar(title: const Text('Sewing')),
    floatingActionButton: FloatingActionButton(
      onPressed: () => context.push('/sewing/new'),
      child: const Icon(Icons.add),
    ),
    body: BlocConsumer<SewingBloc, SewingState>(
      listener: (context, state) {
        if (state is SewingSuccess) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        } else if (state is SewingError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      buildWhen: (previous, current) =>
          current is! SewingSuccess && current is! SewingError,
      builder: (context, state) {
        if (state is SewingLoading &&
            context.read<SewingBloc>().state is! SewingLoaded) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = state is SewingLoaded ? state.items : <SewingEntity>[];

        if (items.isEmpty && state is! SewingLoading) {
          return const Center(child: Text('No Sewing Records'));
        }

        return ListView.builder(
          controller: _scrollController,
          itemCount: items.length + (state is SewingLoading ? 1 : 0),
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
                    context.read<SewingBloc>().add(DeleteSewing(item.id!)),
              ),
            );
          },
        );
      },
    ),
  );
}
