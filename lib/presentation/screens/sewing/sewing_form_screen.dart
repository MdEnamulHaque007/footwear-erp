/// ============================================================================
/// ফাইল: lib/presentation/screens/sewing/sewing_form_screen.dart
/// স্তর: Presentation Screen | মডিউল: Sewing
/// উদ্দেশ্য: Sewing মডিউলের user interface, input, filter ও user interaction উপস্থাপন করে।
/// প্রধান অংশ: SewingFormScreen, _SewingFormScreenState
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/sewing_entity.dart';
import '../../blocs/sewing/sewing_bloc.dart';
import '../../blocs/sewing/sewing_event.dart';
import '../../blocs/sewing/sewing_state.dart';

/// PO-driven Sewing entry form.
///
/// Flow: Sewing Date → PO No → (auto-filled Tag/Company/Project) → Article →
/// Color → cumulative Cutting + Available quantity → Sewing quantity → Save.
class SewingFormScreen extends StatefulWidget {
  const SewingFormScreen({super.key, this.initialItem});
  final SewingEntity? initialItem;

  @override
  State<SewingFormScreen> createState() => _SewingFormScreenState();
}

class _SewingFormScreenState extends State<SewingFormScreen> {
  static const _entryPersons = [
    'Admin',
    'Supervisor',
    'Operator',
    'Store Keeper',
  ];

  bool _isSubmitting = false;
  final voucher = TextEditingController();
  final factory = TextEditingController();
  final sewingDateController = TextEditingController();
  final cuttingQuantityController = TextEditingController(text: '0');
  final availableQuantityController = TextEditingController(text: '0');
  final quantity = TextEditingController();
  final entryPerson = TextEditingController();
  final remarks = TextEditingController();

  String? poNo, article, color;
  DateTime? sewingDate;
  String tagNo = '', company = '', project = '';
  List<String> poNos = [], articles = [], colors = [];
  int cuttingQuantity = 0, availableQuantity = 0;

  /// Live validation message from the BLoC (shown as the quantity field error).
  String? _validationMessage;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    voucher.text = _buildVoucher(today);
    sewingDate = today;
    sewingDateController.text = _formatDate(today);

    final item = widget.initialItem;
    if (item != null) {
      voucher.text = item.voucherNo;
      factory.text = item.factoryName;
      entryPerson.text = item.entryPerson.isEmpty ? '' : item.entryPerson;
      remarks.text = item.remarks;
      poNo = item.poNo;
      tagNo = item.tagNo;
      company = item.company;
      project = item.project;
      article = item.article;
      color = item.color;
      cuttingQuantity = item.cuttingQuantity;
      availableQuantity = 0;
      quantity.text = item.effectiveQuantity.toString();
      sewingDate = item.sewingDate;
      sewingDateController.text = _formatDate(item.sewingDate);
      cuttingQuantityController.text = cuttingQuantity.toString();
      availableQuantityController.text = availableQuantity.toString();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SewingBloc>().add(LoadPONoList());
      if (widget.initialItem != null) {
        _refreshAvailability();
      }
    });
  }

  @override
  void dispose() {
    for (final controller in [
      voucher,
      factory,
      sewingDateController,
      cuttingQuantityController,
      availableQuantityController,
      quantity,
      entryPerson,
      remarks,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Auto voucher: `SEW-YYYYMMDD-XXX`.
  String _buildVoucher(DateTime date) {
    final stamp =
        '${date.year}'
        '${date.month.toString().padLeft(2, '0')}'
        '${date.day.toString().padLeft(2, '0')}';
    final millis = date.millisecondsSinceEpoch.toString();
    return '${AppConstants.sewingVoucherPrefix}-$stamp-'
        '${millis.substring(millis.length - 3)}';
  }

  Future<void> _pickSewingDate() async {
    final today = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: sewingDate ?? today,
      firstDate: DateTime(2020),
      lastDate: DateTime(today.year + 5, today.month, today.day),
    );
    if (selected == null || !mounted) return;
    setState(() {
      sewingDate = selected;
      sewingDateController.text = _formatDate(selected);
    });
    _refreshAvailability();
  }

  /// Reloads cumulative Cutting + Available for the current PO line.
  void _refreshAvailability() {
    final date = sewingDate;
    if (poNo == null || article == null || color == null || date == null) return;
    context.read<SewingBloc>().add(
      LoadAvailableQuantity(
        poNo: poNo!,
        article: article!,
        color: color!,
        sewingDate: date,
        excludeId: widget.initialItem?.id,
      ),
    );
    _validateQuantity();
  }

  void _validateQuantity() {
    final date = sewingDate;
    if (poNo == null || article == null || color == null || date == null) return;
    context.read<SewingBloc>().add(
      ValidateSewing(
        poNo: poNo!,
        article: article!,
        color: color!,
        quantity: int.tryParse(quantity.text) ?? 0,
        sewingDate: date,
        excludeId: widget.initialItem?.id,
      ),
    );
  }

  void _snack(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: IconButton(
        tooltip: 'Back to Sewing List',
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.go('/sewing'),
      ),
      title: Text(
        widget.initialItem == null ? 'New Sewing Record' : 'Edit Sewing Record',
      ),
    ),
    body: BlocListener<SewingBloc, SewingState>(
      listener: (context, state) {
        if (state is PONoListLoaded) {
          setState(() => poNos = state.poNoList);
          final item = widget.initialItem;
          if (item != null && state.poNoList.contains(item.poNo)) {
            context.read<SewingBloc>().add(SelectPO(item.poNo));
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
              cuttingQuantity = 0;
              availableQuantity = 0;
              cuttingQuantityController.text = '0';
              availableQuantityController.text = '0';
            }
          });
          if (article != null) {
            context.read<SewingBloc>().add(
              LoadArticleColors(widget.initialItem!.poNo, article!),
            );
          }
        }
        if (state is ArticleListLoaded) {
          setState(() {
            articles = state.articles;
            if (article != null && _safeValue(article, articles) == null) {
              article = null;
              color = null;
              colors = [];
            }
          });
        }
        if (state is ColorListLoaded) {
          setState(() {
            colors = state.colors;
            if (_safeValue(color, colors) == null) color = null;
          });
          if (widget.initialItem != null && color != null) {
            _refreshAvailability();
          }
        }
        if (state is AvailableQuantityLoaded) {
          setState(() {
            cuttingQuantity = state.cuttingQty;
            availableQuantity = state.availableQty;
            cuttingQuantityController.text = state.cuttingQty.toString();
            availableQuantityController.text = state.availableQty.toString();
          });
        }
        if (state is SewingValidationError) {
          setState(() => _validationMessage = state.message);
        }
        if (state is SewingValidationSuccess) {
          setState(() => _validationMessage = null);
        }
        if (state is SewingSuccess) {
          setState(() => _isSubmitting = false);
          _snack('Sewing saved successfully!');
          Navigator.pop(context);
        }
        if (state is SewingError) {
          setState(() => _isSubmitting = false);
          _snack(state.message);
        }
      },
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(
            controller: sewingDateController,
            readOnly: true,
            onTap: _pickSewingDate,
            decoration: const InputDecoration(
              labelText: 'Sewing Date *',
              suffixIcon: Icon(Icons.calendar_today),
            ),
          ),
          TextField(
            controller: voucher,
            readOnly: true,
            decoration: const InputDecoration(labelText: 'Voucher No.'),
          ),
          TextField(
            controller: factory,
            decoration: const InputDecoration(labelText: 'Factory Name *'),
          ),
          _poDropdown(),
          _readOnly('Tag No', tagNo),
          _readOnly('Company', company),
          _readOnly('Project', project),
          _articleDropdown(),
          _colorDropdown(),
          _readOnlyController('Cutting Quantity', cuttingQuantityController),
          _readOnlyController('Available Quantity', availableQuantityController),
          TextField(
            controller: quantity,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Sewing Quantity *',
              errorText: _validationMessage,
            ),
            onChanged: (_) => _validateQuantity(),
          ),
          DropdownButtonFormField<String>(
            initialValue: entryPerson.text.isEmpty ? null : entryPerson.text,
            decoration: const InputDecoration(labelText: 'Entry Person *'),
            items: _entryPersons
                .toSet()
                .map(
                  (value) => DropdownMenuItem(value: value, child: Text(value)),
                )
                .toList(),
            onChanged: (value) =>
                setState(() => entryPerson.text = value ?? ''),
          ),
          TextField(
            controller: remarks,
            decoration: const InputDecoration(labelText: 'Remarks'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              OutlinedButton(
                onPressed: _isSubmitting ? null : () => context.go('/sewing'),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _save,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Sewing'),
              ),
            ],
          ),
        ],
      ),
    ),
  );



  Widget _poDropdown() {
    final items = _safeItems(poNos);
    return DropdownButtonFormField<String>(
      initialValue: _safeValue(poNo, items),
      decoration: const InputDecoration(labelText: 'PO No *'),
      items: items
          .map((value) => DropdownMenuItem(value: value, child: Text(value)))
          .toList(),
      onChanged: (value) {
        setState(() => poNo = value);
        if (value != null) context.read<SewingBloc>().add(SelectPO(value));
      },
    );
  }

  Widget _articleDropdown() {
    final items = _safeItems(articles);
    return DropdownButtonFormField<String>(
      initialValue: _safeValue(article, items),
      decoration: const InputDecoration(labelText: 'Article *'),
      items: items
          .map((value) => DropdownMenuItem(value: value, child: Text(value)))
          .toList(),
      onChanged: (value) {
        setState(() {
          article = value;
          color = null;
          colors = [];
          cuttingQuantity = 0;
          availableQuantity = 0;
          cuttingQuantityController.text = '0';
          availableQuantityController.text = '0';
        });
        if (value != null && poNo != null) {
          context.read<SewingBloc>().add(LoadArticleColors(poNo!, value));
          _refreshAvailability();
        }
      },
    );
  }

  Widget _colorDropdown() {
    final items = _safeItems(colors);
    return DropdownButtonFormField<String>(
      initialValue: _safeValue(color, items),
      decoration: const InputDecoration(labelText: 'Color *'),
      items: items
          .map((value) => DropdownMenuItem(value: value, child: Text(value)))
          .toList(),
      onChanged: (value) {
        setState(() => color = value);
        if (value != null) _refreshAvailability();
      },
    );
  }

  /// Case-insensitive dedupe so `DropdownButtonFormField` never receives two
  /// items with the same value (which throws an assertion and crashes the form).
  List<String> _safeItems(Iterable<String> values) {
    final seen = <String>{};
    final result = <String>[];
    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) continue;
      if (seen.add(trimmed.toLowerCase())) result.add(trimmed);
    }
    result.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return result;
  }

  /// Only passes a value that actually exists in [items], otherwise null.
  String? _safeValue(String? value, List<String> items) {
    if (value == null) return null;
    final match = items.where(
      (item) => item.toLowerCase() == value.toLowerCase(),
    );
    return match.isEmpty ? null : match.first;
  }

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
  void _save() {
    if (_isSubmitting) return;
    final selectedPO = poNo;
    final selectedArticle = article;
    final selectedColor = color;
    final date = sewingDate;
    if (date == null) {
      _snack('Please select a sewing date');
      return;
    }
    if (selectedPO == null ||
        selectedArticle == null ||
        selectedColor == null ||
        entryPerson.text.trim().isEmpty ||
        factory.text.trim().isEmpty) {
      _snack('Complete all required fields');
      return;
    }
    final qty = int.tryParse(quantity.text) ?? 0;
    if (qty <= 0) {
      _snack('Sewing quantity must be greater than zero');
      return;
    }
    if (qty > availableQuantity) {
      _snack('Sewing quantity must be between 1 and $availableQuantity');
      return;
    }
    setState(() => _isSubmitting = true);
    final item = SewingEntity(
      id: widget.initialItem?.id,
      sl: widget.initialItem?.sl ?? DateTime.now().millisecondsSinceEpoch,
      voucherNo: voucher.text.trim(),
      sewingDate: date,
      poNo: selectedPO,
      tagNo: tagNo,
      company: company,
      project: project,
      article: selectedArticle,
      color: selectedColor,
      cuttingQuantity: cuttingQuantity,
      sewingQuantity: qty,
      factoryName: factory.text.trim(),
      entryPerson: entryPerson.text.trim(),
      remarks: remarks.text.trim(),
      createdAt: widget.initialItem?.createdAt,
      source: widget.initialItem?.source,
      syncStatus: widget.initialItem?.syncStatus,
    );
    context.read<SewingBloc>().add(
      widget.initialItem == null ? CreateSewing(item) : UpdateSewing(item),
    );
  }

  String _formatDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';
}
