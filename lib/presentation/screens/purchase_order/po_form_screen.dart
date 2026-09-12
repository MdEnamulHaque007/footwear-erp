import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/field_parsers.dart';
import '../../../domain/entities/master_lc_entity.dart';
import '../../../domain/entities/po_entity.dart';
import '../../../domain/usecases/purchase_order/validate_po_quantity_usecase.dart';
import '../../blocs/master_lc/master_lc_bloc.dart';
import '../../blocs/master_lc/master_lc_event.dart';
import '../../blocs/master_lc/master_lc_state.dart';
import '../../blocs/purchase_order/po_bloc.dart';
import '../../blocs/purchase_order/po_event.dart';
import '../../blocs/purchase_order/po_state.dart';

class POFormScreen extends StatefulWidget {
  const POFormScreen({super.key, this.initialItem, this.initialTagNo});
  final POEntity? initialItem;
  final String? initialTagNo;

  @override
  State<POFormScreen> createState() => _POFormScreenState();
}

class _POFormScreenState extends State<POFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _companyController = TextEditingController();
  final _projectController = TextEditingController();
  final _brandController = TextEditingController();
  final _poNoController = TextEditingController();
  final _entryPersonController = TextEditingController();
  final _masterLCList = <MasterLCEntity>[];
  final _lineItems = <_LineItemControllers>[];
  String? _selectedTagNo;
  DateTime? _selectedDate;
  POAvailability? _availability;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    final item = widget.initialItem;
    _selectedDate = item?.poDate ?? DateTime.now();
    _dateController.text = _formatDate(_selectedDate!);
    if (item != null) {
      _selectedTagNo = item.tagNo;
      _companyController.text = item.company;
      _projectController.text = item.project;
      _brandController.text = item.brand;
      _poNoController.text = item.poNo;
      _entryPersonController.text = item.entryPerson;
      for (final line in item.effectiveLineItems) {
        _lineItems.add(_LineItemControllers.fromEntity(line));
      }
    } else if (widget.initialTagNo != null) {
      _selectedTagNo = widget.initialTagNo;
      _addLineItem();
    } else {
      _addLineItem();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<MasterLCBloc>().add(LoadMasterLCList(limit: 1000));
      }
    });
  }

  @override
  void dispose() {
    _dateController.dispose();
    _companyController.dispose();
    _projectController.dispose();
    _brandController.dispose();
    _poNoController.dispose();
    _entryPersonController.dispose();
    for (final line in _lineItems) {
      line.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.initialItem == null
            ? 'New Purchase Order'
            : 'Edit Purchase Order',
      ),
    ),
    body: Form(
      key: _formKey,
      child: BlocListener<MasterLCBloc, MasterLCState>(
        listener: (context, state) {
          if (state is MasterLCLoaded) {
            setState(() {
              _masterLCList
                ..clear()
                ..addAll(state.items);
              _setMasterLCFields(_findMasterLC(_selectedTagNo));
              _refreshValidation();
            });
          }
        },
        child: BlocListener<POBloc, POState>(
          listener: (context, state) {
            if (state is POSuccess) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
              Navigator.pop(context);
            } else if (state is POError) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _dateField(),
              _tagField(),
              _readOnlyField('Company', _companyController),
              _readOnlyField('Project', _projectController),
              _textField('Brand', _brandController),
              _textField('PO No.', _poNoController),
              _textField('Entry Person', _entryPersonController),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Line Items',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: _lineItems.length >= 20 ? null : _addLineItem,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Line Item'),
                  ),
                ],
              ),
              ..._lineItems.asMap().entries.map(
                (entry) => _lineItemRow(entry.key, entry.value),
              ),
              _totals(),
              if (_availability != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Available Quantity: ${_availability!.remainingQuantity}    '
                  'Available Value: ${_availability!.remainingValue.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: _validationError == null ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              if (_validationError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _validationError!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _validationError == null ? _save : null,
                child: const Text('Save PO'),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _dateField() => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextFormField(
      controller: _dateController,
      readOnly: true,
      decoration: const InputDecoration(
        labelText: 'PO Date',
        suffixIcon: Icon(Icons.calendar_today),
      ),
      onTap: _selectDate,
      validator: (_) => _selectedDate == null ? 'Please select a date' : null,
    ),
  );

  Widget _tagField() {
    final tags = _masterLCList
        .map((item) => item.tagNo)
        .where((tag) => tag.isNotEmpty)
        .toSet()
        .toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<String>(
        initialValue: tags.contains(_selectedTagNo) ? _selectedTagNo : null,
        decoration: const InputDecoration(labelText: 'Tag No.'),
        items: tags
            .map((tag) => DropdownMenuItem(value: tag, child: Text(tag)))
            .toList(),
        onChanged: tags.isEmpty
            ? null
            : (value) => setState(() {
                _selectedTagNo = value;
                _setMasterLCFields(_findMasterLC(value));
                _refreshValidation();
              }),
        validator: (value) =>
            value == null || value.isEmpty ? 'Tag No. is required' : null,
      ),
    );
  }

  Widget _textField(String label, TextEditingController controller) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      onChanged: (_) => _refreshValidation(),
      validator: (value) =>
          value == null || value.trim().isEmpty ? '$label is required' : null,
    ),
  );

  Widget _readOnlyField(String label, TextEditingController controller) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextFormField(
          controller: controller,
          readOnly: true,
          decoration: InputDecoration(labelText: label),
          validator: (value) => value == null || value.trim().isEmpty
              ? '$label is required'
              : null,
        ),
      );

  Widget _lineItemRow(int index, _LineItemControllers line) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _lineField('Article', line.article)),
                const SizedBox(width: 8),
                Expanded(child: _lineField('Color', line.color)),
                IconButton(
                  tooltip: 'Remove line',
                  onPressed: _lineItems.length == 1
                      ? null
                      : () => setState(() {
                          line.dispose();
                          _lineItems.removeAt(index);
                        }),
                  icon: const Icon(Icons.delete, color: Colors.red),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: _lineField('Quantity', line.quantity, numeric: true),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _lineField(
                    'Unit Price',
                    line.unitPrice,
                    numeric: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: line.quantity,
                    builder: (_, _, _) =>
                        ValueListenableBuilder<TextEditingValue>(
                          valueListenable: line.unitPrice,
                          builder: (_, _, _) => InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'PO Value',
                            ),
                            child: Text(line.value.toStringAsFixed(2)),
                          ),
                        ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _lineField(
    String label,
    TextEditingController controller, {
    bool numeric = false,
  }) => TextFormField(
    controller: controller,
    keyboardType: numeric ? TextInputType.number : TextInputType.text,
    inputFormatters: numeric
        ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
        : null,
    decoration: InputDecoration(labelText: label),
    onChanged: (_) => _refreshValidation(),
    validator: (value) {
      if (value == null || value.trim().isEmpty) return '$label is required';
      if (numeric && parseDouble(value) <= 0) {
        return '$label must be greater than 0';
      }
      return null;
    },
  );

  Widget _totals() => AnimatedBuilder(
    animation: Listenable.merge(
      _lineItems.expand((line) => [line.quantity, line.unitPrice]).toList(),
    ),
    builder: (_, _) => Text(
      'Total Quantity: ${_totalQuantity()}    '
      'Total Value: ${_totalValue().toStringAsFixed(2)}',
      style: const TextStyle(fontWeight: FontWeight.bold),
    ),
  );

  void _addLineItem() => setState(() => _lineItems.add(_LineItemControllers()));

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final lines = _lineItems.map((line) => line.toEntity()).toList();
    final item = POEntity(
      id: widget.initialItem?.id,
      sl: widget.initialItem?.sl ?? DateTime.now().millisecondsSinceEpoch,
      poDate: _selectedDate!,
      tagNo: _selectedTagNo!,
      company: _companyController.text.trim(),
      project: _projectController.text.trim(),
      brand: _brandController.text.trim(),
      poNo: _poNoController.text.trim(),
      entryPerson: _entryPersonController.text.trim(),
      lineItems: lines,
    );
    context.read<POBloc>().add(
      widget.initialItem == null ? CreatePO(item) : UpdatePO(item),
    );
  }

  Future<void> _refreshValidation() async {
    final tag = _selectedTagNo;
    if (tag == null || tag.isEmpty || !mounted) return;
    final candidate = POEntity(
      id: widget.initialItem?.id,
      sl: widget.initialItem?.sl ?? 0,
      poDate: _selectedDate ?? DateTime.now(),
      tagNo: tag,
      company: _companyController.text,
      project: _projectController.text,
      brand: _brandController.text,
      poNo: _poNoController.text,
      entryPerson: _entryPersonController.text,
      lineItems: _lineItems.map((line) => line.toEntity()).toList(),
    );
    final availability = await context.read<POBloc>().getAvailability(candidate);
    if (!mounted) return;
    setState(() {
      _availability = availability;
      if (availability == null) {
        _validationError = null;
      } else if (candidate.totalQuantity > availability.remainingQuantity) {
        _validationError =
            'PO quantity exceeds remaining Master LC quantity. '
            'Available: ${availability.remainingQuantity}';
      } else if (candidate.totalValue > availability.remainingValue) {
        _validationError =
            'PO value exceeds remaining Master LC value. '
            'Available: ${availability.remainingValue.toStringAsFixed(2)}';
      } else {
        _validationError = null;
      }
    });
  }

  int _totalQuantity() =>
      _lineItems.fold(0, (sum, line) => sum + line.quantityValue);
  double _totalValue() => _lineItems.fold(0, (sum, line) => sum + line.value);
  String _formatDate(DateTime date) => DateFormat('dd/MM/yyyy').format(date);

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 5, now.month, now.day),
    );
    if (selected != null && mounted) {
      setState(() {
        _selectedDate = selected;
        _dateController.text = _formatDate(selected);
      });
    }
  }

  MasterLCEntity? _findMasterLC(String? tag) => _masterLCList
      .cast<MasterLCEntity?>()
      .firstWhere((item) => item?.tagNo == tag, orElse: () => null);

  void _setMasterLCFields(MasterLCEntity? item) {
    _companyController.text = item?.company ?? '';
    _projectController.text = item?.project ?? '';
  }
}

class _LineItemControllers {
  _LineItemControllers()
    : article = TextEditingController(),
      color = TextEditingController(),
      quantity = TextEditingController(),
      unitPrice = TextEditingController();

  _LineItemControllers.fromEntity(POLineItemEntity item)
    : article = TextEditingController(),
      color = TextEditingController(),
      quantity = TextEditingController(),
      unitPrice = TextEditingController() {
    article.text = item.article;
    color.text = item.color;
    quantity.text = '${item.poQuantity}';
    unitPrice.text = '${item.unitPrice}';
  }

  final TextEditingController article;
  final TextEditingController color;
  final TextEditingController quantity;
  final TextEditingController unitPrice;

  int get quantityValue => parseInt(quantity.text);
  double get value => quantityValue * parseDouble(unitPrice.text);

  POLineItemEntity toEntity() => POLineItemEntity(
    article: article.text.trim(),
    color: color.text.trim(),
    poQuantity: quantityValue,
    unitPrice: parseDouble(unitPrice.text),
  );

  void dispose() {
    article.dispose();
    color.dispose();
    quantity.dispose();
    unitPrice.dispose();
  }
}
