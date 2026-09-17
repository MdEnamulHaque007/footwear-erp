import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/entities/cutting_entity.dart';
import '../../../domain/usecases/cutting/get_next_voucher_no_usecase.dart';
import '../../blocs/cutting/cutting_bloc.dart';
import '../../blocs/cutting/cutting_event.dart';
import '../../blocs/cutting/cutting_state.dart';

class CuttingFormScreen extends StatefulWidget {
  const CuttingFormScreen({super.key, this.initialItem});
  final CuttingEntity? initialItem;
  @override
  State<CuttingFormScreen> createState() => _CuttingFormScreenState();
}

class _CuttingFormScreenState extends State<CuttingFormScreen> {
  bool _isSubmitting = false;
  final voucher = TextEditingController();
  final factory = TextEditingController();
  final quantity = TextEditingController();
  final cuttingDateController = TextEditingController();
  final poQuantityController = TextEditingController(text: '0');
  final availableQuantityController = TextEditingController(text: '0');
  final entryPerson = TextEditingController();
  final remarks = TextEditingController();
  String? poNo, article, color;
  DateTime? cuttingDate;
  String tagNo = '', company = '', project = '';
  List<String> poNos = [], articles = [], colors = [];
  int poQuantity = 0, availableQuantity = 0;

  @override
  void initState() {
    super.initState();
    final date = DateTime.now();
    cuttingDate = date;
    cuttingDateController.text = _formatDate(date);
    final item = widget.initialItem;
    if (item != null) {
      voucher.text = item.voucherNo;
      factory.text = item.factoryName;
      entryPerson.text = item.entryPerson;
      remarks.text = item.remarks;
      poNo = item.poNo;
      tagNo = item.tagNo;
      company = item.company;
      project = item.project;
      article = item.article;
      color = item.color;
      poQuantity = item.poQuantity;
      availableQuantity = item.poQuantity;
      quantity.text = item.cuttingQuantity.toString();
      cuttingDate = item.cuttingDate;
      cuttingDateController.text = _formatDate(item.cuttingDate);
      poQuantityController.text = poQuantity.toString();
      availableQuantityController.text = availableQuantity.toString();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CuttingBloc>().add(LoadPONoList());
      if (widget.initialItem == null) {
        _loadVoucher(date);
      } else if (poNo != null && article != null && color != null) {
        context.read<CuttingBloc>().add(
          LoadPOQuantity(
            poNo!,
            article!,
            color!,
            excludingId: widget.initialItem?.id,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    for (final controller in [
      voucher,
      factory,
      quantity,
      cuttingDateController,
      poQuantityController,
      availableQuantityController,
      entryPerson,
      remarks,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (_isSubmitting) return;
    final selectedPO = poNo, selectedArticle = article, selectedColor = color;
    final qty = int.tryParse(quantity.text) ?? 0;
    if (cuttingDate == null || voucher.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(content: Text('Please wait for voucher generation')),
      );
      return;
    }
    if (selectedPO == null ||
        selectedArticle == null ||
        selectedColor == null ||
        entryPerson.text.trim().isEmpty ||
        factory.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete all required fields')),
      );
      return;
    }
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cutting quantity must be greater than zero'),
        ),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    final item = CuttingEntity(
      id: widget.initialItem?.id,
      voucherNo: voucher.text.trim(),
      cuttingDate: cuttingDate!,
      poNo: selectedPO,
      tagNo: tagNo,
      company: company,
      project: project,
      article: selectedArticle,
      color: selectedColor,
      poQuantity: poQuantity,
      cuttingQuantity: qty,
      factoryName: factory.text.trim(),
      entryPerson: entryPerson.text.trim(),
      remarks: remarks.text.trim(),
    );
    context.read<CuttingBloc>().add(
      widget.initialItem == null ? CreateCutting(item) : UpdateCutting(item),
    );
  }

  Future<void> _pickCuttingDate() async {
    final today = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: cuttingDate ?? today,
      firstDate: DateTime(2020),
      lastDate: DateTime(today.year + 5, today.month, today.day),
    );
    if (selected != null && mounted) {
      setState(() {
        cuttingDate = selected;
        cuttingDateController.text = _formatDate(selected);
        if (widget.initialItem == null) voucher.clear();
      });
      if (widget.initialItem == null) _loadVoucher(selected);
    }
  }

  Future<void> _loadVoucher(DateTime date) async {
    final result = await GetIt.I<GetNextVoucherNoUseCase>()(date);
    if (!mounted || cuttingDate != date) return;
    result.fold(
      (error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      ),
      (value) => setState(() => voucher.text = value),
    );
  }

  String _formatDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: IconButton(
        tooltip: 'Back to Cutting List',
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.go('/cutting'),
      ),
      title: Text(
        widget.initialItem == null
            ? 'New Cutting Record'
            : 'Edit Cutting Record',
      ),
    ),
    body: BlocListener<CuttingBloc, CuttingState>(
      listener: (context, state) {
        if (state is PONoListLoaded) {
          setState(() => poNos = state.poNoList);
          if (widget.initialItem != null &&
              state.poNoList.contains(widget.initialItem!.poNo)) {
            context.read<CuttingBloc>().add(SelectPO(widget.initialItem!.poNo));
          }
        }
        if (state is POSelected) {
          setState(() {
            tagNo = state.tagNo;
            company = state.company;
            project = state.project;
            articles = state.articles;
            article = widget.initialItem?.article;
            color = widget.initialItem?.color;
            colors = [];
            if (article == null) {
              poQuantity = 0;
              availableQuantity = 0;
              poQuantityController.text = '0';
              availableQuantityController.text = '0';
            }
          });
          if (article != null) {
            context.read<CuttingBloc>().add(
              LoadArticleColors(widget.initialItem!.poNo, article!),
            );
          }
        }
        if (state is ArticleListLoaded) {
          setState(() => articles = state.articles);
        }
        if (state is ColorListLoaded) {
          setState(() => colors = state.colors);
          if (widget.initialItem != null && color != null) {
            context.read<CuttingBloc>().add(
              LoadPOQuantity(
                widget.initialItem!.poNo,
                widget.initialItem!.article,
                widget.initialItem!.color,
                excludingId: widget.initialItem!.id,
              ),
            );
          }
        }
        if (state is AvailableQuantityLoaded) {
          setState(() {
            availableQuantity = state.availableQty;
            poQuantity = state.poQty;
            poQuantityController.text = state.poQty.toString();
            availableQuantityController.text = state.availableQty.toString();
          });
        }
        if (state is CuttingSuccess) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cutting saved successfully!')),
          );
          Navigator.pop(context);
        }
        if (state is CuttingError || state is CuttingValidationError) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state is CuttingError
                    ? state.message
                    : (state as CuttingValidationError).message,
              ),
            ),
          );
        }
      },
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(
            controller: voucher,
            readOnly: true,
            decoration: const InputDecoration(labelText: 'Voucher No.'),
          ),
          TextField(
            controller: cuttingDateController,
            readOnly: true,
            onTap: _pickCuttingDate,
            decoration: const InputDecoration(
              labelText: 'Cutting Date *',
              suffixIcon: Icon(Icons.calendar_today),
            ),
          ),
          TextField(
            controller: factory,
            decoration: const InputDecoration(labelText: 'Factory Name *'),
          ),
          DropdownButtonFormField<String>(
            initialValue: poNo,
            decoration: const InputDecoration(labelText: 'PO No *'),
            items: poNos
                .map(
                  (value) => DropdownMenuItem(value: value, child: Text(value)),
                )
                .toList(),
            onChanged: (value) {
              setState(() => poNo = value);
              if (value != null) {
                context.read<CuttingBloc>().add(SelectPO(value));
              }
            },
          ),
          _readOnly('Tag No', tagNo),
          _readOnly('Company', company),
          _readOnly('Project', project),
          DropdownButtonFormField<String>(
            initialValue: article,
            decoration: const InputDecoration(labelText: 'Article *'),
            items: articles
                .map(
                  (value) => DropdownMenuItem(value: value, child: Text(value)),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                article = value;
                color = null;
                colors = [];
              });
              if (value != null && poNo != null) {
                context.read<CuttingBloc>().add(
                  LoadArticleColors(poNo!, value),
                );
              }
            },
          ),
          DropdownButtonFormField<String>(
            initialValue: color,
            decoration: const InputDecoration(labelText: 'Color *'),
            items: colors
                .map(
                  (value) => DropdownMenuItem(value: value, child: Text(value)),
                )
                .toList(),
            onChanged: (value) {
              setState(() => color = value);
              if (value != null && poNo != null && article != null) {
                context.read<CuttingBloc>().add(
                  LoadPOQuantity(poNo!, article!, value),
                );
              }
            },
          ),
          _readOnlyController('PO Quantity', poQuantityController),
          _readOnlyController(
            'PO Balance Before Entry',
            availableQuantityController,
          ),
          Builder(
            builder: (context) {
              final entered = int.tryParse(quantity.text) ?? 0;
              final projectedExcess = entered - availableQuantity;
              final excess = projectedExcess > 0 ? projectedExcess : 0;
              return _readOnly('Excess After Entry', excess.toString());
            },
          ),
          TextField(
            controller: quantity,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Cutting Quantity *'),
            onChanged: (_) {
              setState(() {});
              if (poNo != null && article != null && color != null) {
                context.read<CuttingBloc>().add(
                  ValidateCutting(
                    poNo!,
                    article!,
                    color!,
                    poQuantity,
                    int.tryParse(quantity.text) ?? 0,
                    excludingId: widget.initialItem?.id,
                  ),
                );
              }
            },
          ),
          TextField(
            controller: entryPerson,
            decoration: const InputDecoration(labelText: 'Entry Person *'),
          ),
          TextField(
            controller: remarks,
            decoration: const InputDecoration(labelText: 'Remarks'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _save,
            child: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save Cutting'),
          ),
        ],
      ),
    ),
  );

  Widget _readOnly(String label, String value) => InputDecorator(
    decoration: InputDecoration(labelText: label),
    child: Text(value.isEmpty ? '-' : value),
  );

  Widget _readOnlyController(String label, TextEditingController controller) =>
      TextField(
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(labelText: label),
      );
}
