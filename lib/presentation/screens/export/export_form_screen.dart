/// ============================================================================
/// ফাইল: lib/presentation/screens/export/export_form_screen.dart
/// স্তর: Presentation Screen | মডিউল: Export
/// উদ্দেশ্য: Export মডিউলের user interface, input, filter ও user interaction উপস্থাপন করে।
/// প্রধান অংশ: ExportFormScreen, _ExportFormScreenState
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/export_entity.dart';
import '../../blocs/export/export_bloc.dart';
import '../../blocs/export/export_event.dart';
import '../../blocs/export/export_state.dart';

/// PO-driven Export (shipment) entry form.
///
/// Flow: Export Date → PO No (Issue-filtered) → (auto-filled
/// Tag/Company/Project) → Article → Color → (auto Unit Price) → cumulative
/// Issue + Available → Quantity → auto Export Value → Save.
class ExportFormScreen extends StatefulWidget {
  const ExportFormScreen({super.key, this.initialItem});
  final ExportEntity? initialItem;

  @override
  State<ExportFormScreen> createState() => _ExportFormScreenState();
}

class _ExportFormScreenState extends State<ExportFormScreen> {
  static const _entryPersons = [
    'Admin',
    'Supervisor',
    'Operator',
    'Store Keeper',
  ];

  bool _isSubmitting = false;
  final voucher = TextEditingController();
  final factory = TextEditingController();
  final exportDateController = TextEditingController();
  final unitPriceController = TextEditingController(text: '0');
  final issueQuantityController = TextEditingController(text: '0');
  final availableQuantityController = TextEditingController(text: '0');
  final exportValueController = TextEditingController(text: '0');
  final quantity = TextEditingController();
  final entryPerson = TextEditingController();
  final remarks = TextEditingController();

  String? poNo, article, color;
  DateTime? exportDate;
  String tagNo = '', company = '', project = '';
  List<String> poNos = [], articles = [], colors = [];
  int issueQuantity = 0, availableQuantity = 0;
  double unitPrice = 0, exportValue = 0;

  /// Live validation message from the BLoC (shown as the quantity field error).
  String? _validationMessage;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    exportDate = today;
    exportDateController.text = _formatDate(today);
    voucher.text = _suggestVoucher(today);

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
      unitPrice = item.unitPrice;
      exportValue = item.exportValue;
      issueQuantity = item.issueQuantity;
      availableQuantity = 0;
      quantity.text = item.quantity.toString();
      exportDate = item.exportDate;
      exportDateController.text = _formatDate(item.exportDate);
      unitPriceController.text = _money(unitPrice);
      issueQuantityController.text = issueQuantity.toString();
      availableQuantityController.text = availableQuantity.toString();
      exportValueController.text = _money(exportValue);
      poNos = item.poNo.trim().isEmpty ? [] : [item.poNo.trim()];
      articles = item.article.trim().isEmpty ? [] : [item.article.trim()];
      colors = item.color.trim().isEmpty ? [] : [item.color.trim()];
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExportBloc>().add(LoadPONoList());
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
      exportDateController,
      unitPriceController,
      issueQuantityController,
      availableQuantityController,
      exportValueController,
      quantity,
      entryPerson,
      remarks,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Suggested voucher: `EXP-YYYYMMDD-XXX` (still manually editable).
  String _suggestVoucher(DateTime date) {
    final stamp =
        '${date.year}'
        '${date.month.toString().padLeft(2, '0')}'
        '${date.day.toString().padLeft(2, '0')}';
    final millis = date.millisecondsSinceEpoch.toString();
    return '${AppConstants.exportVoucherPrefix}-$stamp-'
        '${millis.substring(millis.length - 3)}';
  }

  Future<void> _pickExportDate() async {
    final today = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: exportDate ?? today,
      firstDate: DateTime(2020),
      lastDate: DateTime(today.year + 5, today.month, today.day),
    );
    if (selected == null || !mounted) return;
    setState(() {
      exportDate = selected;
      exportDateController.text = _formatDate(selected);
    });
    _refreshAvailability();
  }

  String _formatDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';

  String _money(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);

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

  /// Auto calculation: Quantity × Unit Price.
  void _recalculateValue() {
    final qty = int.tryParse(quantity.text) ?? 0;
    setState(() {
      exportValue = qty * unitPrice;
      exportValueController.text = _money(exportValue);
    });
  }

  /// Reloads cumulative Issue + Available for the current PO line/date.
  void _refreshAvailability() {
    final date = exportDate;
    if (poNo == null || article == null || color == null || date == null) return;
    context.read<ExportBloc>().add(
      LoadAvailableQuantity(
        poTagNo: tagNo,
        poNo: poNo!,
        article: article!,
        color: color!,
        exportDate: date,
        excludeId: widget.initialItem?.id,
      ),
    );
    _validateQuantity();
  }

  void _validateQuantity() {
    final date = exportDate;
    if (poNo == null || article == null || color == null || date == null) return;
    context.read<ExportBloc>().add(
      ValidateExport(
        poTagNo: tagNo,
        poNo: poNo!,
        article: article!,
        color: color!,
        quantity: int.tryParse(quantity.text) ?? 0,
        exportDate: date,
        excludeId: widget.initialItem?.id,
      ),
    );
  }

  void _snack(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  void _save() {
    if (_isSubmitting) return;
    final selectedPO = poNo;
    final selectedArticle = article;
    final selectedColor = color;
    final date = exportDate;
    if (date == null) {
      _snack('Please select an export date');
      return;
    }
    if (voucher.text.trim().isEmpty) {
      _snack('Please enter a voucher number');
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
      _snack('Export quantity must be greater than zero');
      return;
    }
    if (qty > availableQuantity) {
      _snack('Export quantity must be between 1 and $availableQuantity');
      return;
    }
    setState(() => _isSubmitting = true);
    final item = ExportEntity(
      id: widget.initialItem?.id,
      sl: widget.initialItem?.sl ?? DateTime.now().millisecondsSinceEpoch,
      voucherNo: voucher.text.trim(),
      exportDate: date,
      poTagNo: tagNo,
      quantity: qty,
      entryPerson: entryPerson.text.trim(),
      poNo: selectedPO,
      tagNo: tagNo,
      company: company,
      project: project,
      article: selectedArticle,
      color: selectedColor,
      factoryName: factory.text.trim(),
      unitPrice: unitPrice,
      exportValue: exportValue,
      issueQuantity: issueQuantity,
      remarks: remarks.text.trim(),
      source: widget.initialItem?.source,
      syncStatus: widget.initialItem?.syncStatus,
      createdAt: widget.initialItem?.createdAt,
    );
    context.read<ExportBloc>().add(
      widget.initialItem == null ? CreateExport(item) : UpdateExport(item),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: IconButton(
        tooltip: 'Back to Export List',
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.go('/export'),
      ),
      title: Text(
        widget.initialItem == null ? 'New Export Record' : 'Edit Export Record',
      ),
    ),
    body: BlocListener<ExportBloc, ExportState>(
      listener: (context, state) {
        if (state is PONoListLoaded) {
          setState(() {
            poNos = state.poNoList;
            if (poNo != null && _safeValue(poNo, _safeItems(poNos)) == null) {
              poNo = null;
            }
          });
          final item = widget.initialItem;
          if (item != null) {
            final match = _safeItems(state.poNoList).where(
              (value) => value.toLowerCase() == item.poNo.trim().toLowerCase(),
            );
            if (match.isNotEmpty) {
              setState(() => poNo = match.first);
              context.read<ExportBloc>().add(SelectPO(match.first));
            }
          }
        }
        if (state is POSelected) {
          setState(() {
            tagNo = state.tagNo;
            company = state.company;
            project = state.project;
            articles = state.articles;
            final keep = widget.initialItem != null;
            article = keep
                ? _safeValue(widget.initialItem!.article, articles)
                : null;
            color = article == null ? null : widget.initialItem!.color;
            colors = color == null ? [] : [color!];
            if (article == null) {
              issueQuantity = 0;
              availableQuantity = 0;
              issueQuantityController.text = '0';
              availableQuantityController.text = '0';
            }
          });
          if (article != null) {
            context.read<ExportBloc>().add(
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
            context.read<ExportBloc>().add(
              LoadUnitPrice(
                widget.initialItem!.poNo,
                widget.initialItem!.article,
                widget.initialItem!.color,
              ),
            );
            _refreshAvailability();
          }
        }
        if (state is UnitPriceLoaded) {
          setState(() {
            unitPrice = state.unitPrice;
            unitPriceController.text = _money(state.unitPrice);
          });
          _recalculateValue();
        }
        if (state is AvailableQuantityLoaded) {
          setState(() {
            issueQuantity = state.issueQty;
            availableQuantity = state.availableQty;
            issueQuantityController.text = state.issueQty.toString();
            availableQuantityController.text = state.availableQty.toString();
          });
        }
        if (state is ExportValidationError) {
          setState(() => _validationMessage = state.message);
        }
        if (state is ExportValidationSuccess) {
          setState(() => _validationMessage = null);
        }
        if (state is ExportSuccess) {
          setState(() => _isSubmitting = false);
          _snack('Export saved successfully!');
          Navigator.pop(context);
        }
        if (state is ExportError) {
          setState(() => _isSubmitting = false);
          _snack(state.message);
        }
      },
      child: _form(),
    ),
  );

  Widget _form() => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      TextField(
        controller: exportDateController,
        readOnly: true,
        onTap: _pickExportDate,
        decoration: const InputDecoration(
          labelText: 'Export Date *',
          suffixIcon: Icon(Icons.calendar_today),
        ),
      ),
      TextField(
        controller: voucher,
        decoration: const InputDecoration(
          labelText: 'Voucher No. *',
          helperText: 'Format: EXP-YYYYMMDD-XXX',
        ),
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
      _readOnlyController('Unit Price', unitPriceController),
      _readOnlyController('Issue Quantity', issueQuantityController),
      _readOnlyController('Available Quantity', availableQuantityController),
      TextField(
        controller: quantity,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: 'Export Quantity *',
          errorText: _validationMessage,
        ),
        onChanged: (_) {
          _recalculateValue();
          _validateQuantity();
        },
      ),
      _readOnlyController('Export Value', exportValueController),
      DropdownButtonFormField<String>(
        initialValue: entryPerson.text.isEmpty ? null : entryPerson.text,
        decoration: const InputDecoration(labelText: 'Entry Person *'),
        items: _entryPersons
            .toSet()
            .map((value) => DropdownMenuItem(value: value, child: Text(value)))
            .toList(),
        onChanged: (value) => setState(() => entryPerson.text = value ?? ''),
      ),
      TextField(
        controller: remarks,
        decoration: const InputDecoration(labelText: 'Remarks'),
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          OutlinedButton(
            onPressed: _isSubmitting ? null : () => context.go('/export'),
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
                : const Text('Save Export'),
          ),
        ],
      ),
    ],
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
        setState(() {
          poNo = value;
          article = null;
          color = null;
          articles = [];
          colors = [];
        });
        if (value != null) context.read<ExportBloc>().add(SelectPO(value));
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
          issueQuantity = 0;
          availableQuantity = 0;
          issueQuantityController.text = '0';
          availableQuantityController.text = '0';
        });
        if (value != null && poNo != null) {
          context.read<ExportBloc>().add(LoadArticleColors(poNo!, value));
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
        if (value != null && poNo != null && article != null) {
          context.read<ExportBloc>().add(
            LoadUnitPrice(poNo!, article!, value),
          );
          _refreshAvailability();
        }
      },
    );
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
}
