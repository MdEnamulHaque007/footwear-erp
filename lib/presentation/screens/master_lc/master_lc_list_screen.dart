import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/entities/master_lc_entity.dart';
import '../../blocs/master_lc/master_lc_bloc.dart';
import '../../blocs/master_lc/master_lc_event.dart';
import '../../blocs/master_lc/master_lc_state.dart';

class MasterLCListScreen extends StatefulWidget {
  const MasterLCListScreen({super.key});

  @override
  State<MasterLCListScreen> createState() => _MasterLCListScreenState();
}

class _MasterLCListScreenState extends State<MasterLCListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MasterLCBloc>().add(LoadMasterLCList());
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final bloc = context.read<MasterLCBloc>();
      if (bloc.state is MasterLCLoaded) {
        bloc.add(LoadMoreMasterLC());
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
    appBar: AppBar(title: const Text('Master LC')),
    floatingActionButton: FloatingActionButton(
      onPressed: () => context.push('/master-lc/new'),
      child: const Icon(Icons.add),
    ),
    body: BlocConsumer<MasterLCBloc, MasterLCState>(
      listener: (context, state) {
        if (state is MasterLCSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        } else if (state is MasterLCError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      buildWhen: (previous, current) => current is! MasterLCSuccess && current is! MasterLCError,
      builder: (context, state) {
        if (state is MasterLCLoading && context.read<MasterLCBloc>().state is! MasterLCLoaded) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final items = state is MasterLCLoaded ? state.items : <MasterLCEntity>[];
        
        if (items.isEmpty && state is! MasterLCLoading) {
          return const Center(child: Text('No Master LC records'));
        }
        
        return ListView.builder(
          controller: _scrollController,
          itemCount: items.length + (state is MasterLCLoading ? 1 : 0),
          itemBuilder: (_, index) {
            if (index == items.length) {
              return const Center(child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ));
            }
            final item = items[index];
            return ListTile(
              title: Text(item.tagNo),
              subtitle: Text(
                '${item.project} | ${item.company} | Qty: ${item.masterLcQuantity}',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () =>
                    context.read<MasterLCBloc>().add(DeleteMasterLC(item.id!)),
              ),
            );
          },
        );
      },
    ),
  );
}
