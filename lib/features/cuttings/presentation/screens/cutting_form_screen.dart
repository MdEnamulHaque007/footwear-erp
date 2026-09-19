import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/models/cutting_model.dart';
import '../../data/repositories/purchase_order_repository.dart';
import '../providers/cutting_provider.dart';

class CuttingFormScreen extends ConsumerStatefulWidget {
  const CuttingFormScreen({
    super.key,
    this.initialCutting,
    this.isEdit = false,
  });

  final Cutting? initialCutting;
  final bool isEdit;

  @override
  ConsumerState<CuttingFormScreen> createState() => _CuttingFormScreenState();
}

class _CuttingFormScreenState extends ConsumerState<CuttingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _voucherController = TextEditingController();
  final _factoryController = TextEditingController();
  final _poController = TextEditingController();
  final _articleController = TextEditingController();
  final _colorController = TextEditingController();
  final _quantityController = TextEditingController();
  final _entryPersonController = TextEditingController();

  final _poRepository = PurchaseOrderRepository();
  List<String> _poNos = const [];

  @override
  void initState() {
    super.initState();
    final notifier = ref.read(cuttingFormProvider.notifier);
    if (widget.initialCutting == null) {
      ref.invalidate(cuttingFormProvider);
    }
    if (widget.initialCutting != null) {
      notifier.setCutting(widget.initialCutting!);
    }
    final cutting =
        widget.initialCutting ?? ref.read(cuttingFormProvider).cutting;
    _fillControllers(cutting);
    _loadPoNos();
  }

  void _fillControllers(Cutting cutting) {
    _dateController.text =
        DateFormat('dd-MMM-yyyy').format(cutting.cuttingDate);
    _voucherController.text = cutting.voucherNo;
    _factoryController.text = cutting.factoryName;
    _poController.text = cutting.poNo;
    _articleController.text = cutting.article;
    _colorController.text = cutting.color;
    _quantityController.text = cutting.cuttingQuantity.toString();
    _entryPersonController.text = cutting.entryPerson ?? '';
  }

  @override
  void dispose() {
    _dateController.dispose();
    _voucherController.dispose();
    _factoryController.dispose();
    _poController.dispose();
    _articleController.dispose();
    _colorController.dispose();
    _quantityController.dispose();
    _entryPersonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(cuttingFormProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEdit
              ? 'Edit Cutting / কাটিং সম্পাদনা'
              : 'New Cutting / নতুন কাটিং',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _dateField(),
            const SizedBox(height: 12),
            _textField(
              _voucherController,
              'V.No / ভাউচার নং',
              requiredField: true,
              onChanged: (v) =>
                  ref.read(cuttingFormProvider.notifier).update(voucherNo: v),
            ),
            const SizedBox(height: 12),
            _textField(
              _factoryController,
              'Factory / কারখানা',
              onChanged: (v) =>
                  ref.read(cuttingFormProvider.notifier).update(factoryName: v),
            ),
            const SizedBox(height: 12),
            _poAutocomplete(),
            const SizedBox(height: 12),
            _textField(
              _articleController,
              'Article No / আর্টিকেল নং',
              requiredField: true,
              onChanged: (v) {
                ref.read(cuttingFormProvider.notifier).update(article: v);
                _refreshLineQuantity();
              },
            ),
            const SizedBox(height: 12),
            _textField(
              _colorController,
              'Color / রং',
              requiredField: true,
              onChanged: (v) {
                ref.read(cuttingFormProvider.notifier).update(color: v);
                _refreshLineQuantity();
              },
            ),
            const SizedBox(height: 12),
            _textField(
              _quantityController,
              'Quantity / পরিমাণ',
              requiredField: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                final quantity = int.tryParse(v ?? '');
                if (quantity == null || quantity <= 0) {
                  return 'Quantity must be greater than 0';
                }
                return null;
              },
              onChanged: (v) => ref.read(cuttingFormProvider.notifier).update(
                    cuttingQuantity: int.tryParse(v) ?? 0,
                  ),
            ),
            const SizedBox(height: 12),
            _textField(
              _entryPersonController,
              'Entry Person / এন্ট্রি ব্যক্তি',
              onChanged: (v) =>
                  ref.read(cuttingFormProvider.notifier).update(entryPerson: v),
            ),
            const SizedBox(height: 18),
            _autoField('Tag No / ট্যাগ নং', formState.cutting.tagNo),
            const SizedBox(height: 10),
            _autoField('Company / কোম্পানি', formState.cutting.company),
            const SizedBox(height: 10),
            _autoField('Project / প্রজেক্ট', formState.cutting.project),
            const SizedBox(height: 10),
            _autoField(
              'PO Quantity / PO পরিমাণ',
              formState.cutting.poQuantity.toString(),
            ),
            if (formState.errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                formState.errorMessage!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: formState.status == CuttingFormStatus.loading
                  ? null
                  : _save,
              icon: formState.status == CuttingFormStatus.loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(
                widget.isEdit ? 'Update / আপডেট' : 'Save / সংরক্ষণ',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateField() {
    return TextFormField(
      controller: _dateController,
      readOnly: true,
      decoration: const InputDecoration(
        labelText: 'Date / তারিখ *',
        border: OutlineInputBorder(),
        suffixIcon: Icon(Icons.calendar_today),
      ),
      validator: (_) => 'Date is required',
      onTap: () async {
        final current = ref.read(cuttingFormProvider).cutting.cuttingDate;
        final picked = await showDatePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
          initialDate: current,
        );
        if (picked == null) return;
        _dateController.text = DateFormat('dd-MMM-yyyy').format(picked);
        ref.read(cuttingFormProvider.notifier).update(cuttingDate: picked);
      },
    );
  }

  Widget _textField(
    TextEditingController controller,
    String label, {
    bool requiredField = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: requiredField ? '$label *' : label,
        border: const OutlineInputBorder(),
      ),
      validator: validator ??
          (requiredField
              ? (v) => v == null || v.trim().isEmpty ? 'Required' : null
              : null),
      onChanged: onChanged,
    );
  }

  Widget _autoField(String label, String value) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: const OutlineInputBorder(),
      ),
      child: Text(value),
    );
  }

  Widget _poAutocomplete() {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: _poController.text),
      optionsBuilder: (textEditingValue) {
        final query = textEditingValue.text.trim().toLowerCase();
        if (query.isEmpty) return _poNos;
        return _poNos.where((po) => po.toLowerCase().contains(query));
      },
      onSelected: (value) {
        _poController.text = value;
        ref.read(cuttingFormProvider.notifier).update(poNo: value);
        _loadPo(value);
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: const InputDecoration(
            labelText: 'PO No / PO নং *',
            border: OutlineInputBorder(),
          ),
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Required' : null,
          onChanged: (value) {
            _poController.text = value;
            ref.read(cuttingFormProvider.notifier).update(poNo: value);
          },
          onFieldSubmitted: (_) => onFieldSubmitted(),
        );
      },
    );
  }

  Future<void> _loadPoNos() async {
    try {
      final values = await _poRepository.getPoNos();
      if (!mounted) return;
      setState(() => _poNos = values);
    } catch (_) {}

    if (_poController.text.trim().isNotEmpty) {
      await _loadPo(_poController.text.trim());
    }
  }

  Future<void> _loadPo(String poNo) async {
    if (poNo.trim().isEmpty) return;
    try {
      final po = await _poRepository.getByPoNo(poNo);
      if (!mounted) return;
      if (po == null) {
        ref.read(cuttingFormProvider.notifier).update(
              tagNo: '',
              company: '',
              project: '',
              poQuantity: 0,
            );
        return;
      }

      final article = _articleController.text.trim().toLowerCase();
      final color = _colorController.text.trim().toLowerCase();
      PurchaseOrderLine? line;
      for (final item in po.lineItems) {
        if (item.article.toLowerCase() == article &&
            item.color.toLowerCase() == color) {
          line = item;
          break;
        }
      }

      ref.read(cuttingFormProvider.notifier).update(
            tagNo: po.tagNo,
            company: po.company,
            project: po.project,
            poQuantity: line?.poQuantity ?? 0,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PO lookup failed: $e')),
        );
      }
    }
  }

  Future<void> _refreshLineQuantity() async {
    final poNo = _poController.text.trim();
    if (poNo.isEmpty) return;
    await _loadPo(poNo);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final cutting = ref.read(cuttingFormProvider).cutting;
    if (cutting.poQuantity > 0 &&
        cutting.cuttingQuantity > cutting.poQuantity) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('PO Quantity Warning'),
          content: Text(
            'Cutting quantity (${cutting.cuttingQuantity) is greater than '
            'PO quantity (${cutting.poQuantity). Do you want to continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Override / Continue'),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }

    if (widget.isEdit) {
      try {
        await ref.read(cuttingRepositoryProvider).update(cutting);
        if (mounted) context.pop();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      }
      return;
    }

    final ok = await ref.read(cuttingFormProvider.notifier).save();
    if (ok && mounted) context.pop();
  }
}
