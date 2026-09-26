/// ============================================================================
/// ফাইল: lib/presentation/screens/production/production_form_screen.dart
/// স্তর: Presentation Screen | মডিউল: Production/Lasting
/// উদ্দেশ্য: Production/Lasting মডিউলের user interface, input, filter ও user interaction উপস্থাপন করে।
/// প্রধান অংশ: ProductionFormScreen, _ProductionFormScreenState
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/production_entity.dart';
import '../../blocs/production/production_bloc.dart';
import '../../blocs/production/production_event.dart';
import '../../blocs/production/production_state.dart';

/// Lasting/DIP production entry form.
///
/// Flow: Production Date → PO No → (auto-filled Tag/Company/Project) →
/// Article → Color → (auto Unit Price) → cumulative Sewing + Available →
/// Quantity → auto Production Value → Save.
class ProductionFormScreen extends StatefulWidget {
  const ProductionFormScreen({super.key, this.initialItem});
  final ProductionEntity? initialItem;

  @override
  State<ProductionFormScreen> createState() => _ProductionFormScreenState();
}

class _ProductionFormScreenState extends State<ProductionFormScreen> {
  static const _entryPersons = [
    'Admin',
    'Supervisor',
    'Operator',
    'Store Keeper',
  ];

  bool _isSubmitting = false;
  final voucher = TextEditingController();
  final factory = TextEditingController();
  final productionDateController = TextEditingController();
  final unitPriceController = TextEditingController(text: '0');
  final sewingQuantityController = TextEditingController(text: '0');
  final availableQuantityController = TextEditingController(text: '0');
  final productionValueController = TextEditingController(text: '0');
  final quantity = TextEditingController();
  final entryPerson = TextEditingController();
  final remarks = TextEditingController();

  String? poNo, article, color;
  DateTime? productionDate;
  String tagNo = '', company = '', project = '';
  List<String> poNos = [], articles = [], colors = [];
  int sewingQuantity = 0, availableQuantity = 0;
  double unitPrice = 0, productionValue = 0;

  /// Live validation message from the BLoC (shown as the quantity field error).
  String? _validationMessage;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    voucher.text = _buildVoucher(today);
    productionDate = today;
    productionDateController.text = _formatDate(today);

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
      productionValue = item.productionValue;
      sewingQuantity = item.sewingQuantity;
      availableQuantity = 0;
      // Pre-fill the dropdowns with the record's own values so the item list
      // always contains the current selection (avoids the assertion that fires
      // when a DropdownButton value has no matching item).
      articles = item.article.trim().isEmpty ? [] : [item.article.trim()];
      colors = item.color.trim().isEmpty ? [] : [item.color.trim()];
      quantity.text = item.quantity.toString();
      productionDate = item.productionDate;
      productionDateController.text = _formatDate(item.productionDate);
      unitPriceController.text = _money(unitPrice);
      sewingQuantityController.text = sewingQuantity.toString();
      availableQuantityController.text = availableQuantity.toString();
      productionValueController.text = _money(productionValue);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductionBloc>().add(LoadPONoList());
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
      productionDateController,
      unitPriceController,
      sewingQuantityController,
      availableQuantityController,
      productionValueController,
      quantity,
      entryPerson,
      remarks,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Auto voucher: `PRO-YYYYMMDD-XXX`.
  String _buildVoucher(DateTime date) {
    final stamp =
        '${date.year}'
        '${date.month.toString().padLeft(2, '0')}'
        '${date.day.toString().padLeft(2, '0')}';
    final millis = date.millisecondsSinceEpoch.toString();
    return '${AppConstants.productionVoucherPrefix}-$stamp-'
        '${millis.substring(millis.length - 3)}';
  }

  Future<void> _pickProductionDate() async {
    final today = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: productionDate ?? today,
      firstDate: DateTime(2020),
      lastDate: DateTime(today.year + 5, today.month, today.day),
    );
    if (selected == null || !mounted) return;
    setState(() {
      productionDate = selected;
      productionDateController.text = _formatDate(selected);
    });
    _refreshAvailability();
  }

  String _formatDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';

  String _money(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);

  /// Auto calculation: Quantity × Unit Price.
  void _recalculateValue() {
    final qty = int.tryParse(quantity.text) ?? 0;
    setState(() {
      productionValue = qty * unitPrice;
      productionValueController.text = _money(productionValue);
    });
  }

  /// Reloads cumulative Sewing + Available for the current PO line/date.
  void _refreshAvailability() {
    final date = productionDate;
    if (poNo == null || article == null || color == null || date == null) return;
    context.read<ProductionBloc>().add(
      LoadAvailableQuantity(
        poTagNo: tagNo,
        poNo: poNo!,
        article: article!,
        color: color!,
        productionDate: date,
        excludeId: widget.initialItem?.id,
      ),
    );
    _validateQuantity();
  }

  void _validateQuantity() {
    final date = productionDate;
    if (poNo == null || article == null || color == null || date == null) return;
    context.read<ProductionBloc>().add(
      ValidateProduction(
        poTagNo: tagNo,
        poNo: poNo!,
        article: article!,
        color: color!,
        quantity: int.tryParse(quantity.text) ?? 0,
        productionDate: date,
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
        tooltip: 'Back to Production List',
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.go('/production'),
      ),
      title: Text(
        widget.initialItem == null
            ? 'New Production Record'
            : 'Edit Production Record',
      ),
    ),
    body: BlocListener<ProductionBloc, ProductionState>(
      listener: (context, state) {
        if (state is PONoListLoaded) {
          setState(() {
            poNos = state.poNoList;
            // Guard the edit-mode PO against a stale value.
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
              context.read<ProductionBloc>().add(SelectPO(match.first));
            }
          }
        }
        if (state is POSelected) {
          setState(() {
            tagNo = state.tagNo;
            company = state.company;
            project = state.project;
            articles = state.articles;
            // Only keep the edit-mode selection when the sewing-sourced list
            // still offers it; otherwise start clean so no DropdownButton
            // value is left without a matching item.
            final keep = widget.initialItem != null;
            article = keep
                ? _safeValue(widget.initialItem!.article, articles)
                : null;
            color = article == null ? null : widget.initialItem!.color;
            colors = color == null ? [] : [color!];
            if (article == null) {
              sewingQuantity = 0;
              availableQuantity = 0;
              sewingQuantityController.text = '0';
              availableQuantityController.text = '0';
            }
          });
          if (article != null) {
            context.read<ProductionBloc>().add(
              LoadArticleColors(widget.initialItem!.poNo, article!),
            );
          }
        }
        if (state is ArticleListLoaded) {
          setState(() {
            articles = state.articles;
            // Guard against a stale selection that is no longer offered.
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
            context.read<ProductionBloc>().add(
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
            sewingQuantity = state.sewingQty;
            availableQuantity = state.availableQty;
            sewingQuantityController.text = state.sewingQty.toString();
            availableQuantityController.text = state.availableQty.toString();
          });
        }
        if (state is ProductionValidationError) {
          setState(() => _validationMessage = state.message);
        }
        if (state is ProductionValidationSuccess) {
          setState(() => _validationMessage = null);
        }
        if (state is ProductionSuccess) {
          setState(() => _isSubmitting = false);
          _snack('Production saved successfully!');
          Navigator.pop(context);
        }
        if (state is ProductionError) {
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
        controller: productionDateController,
        readOnly: true,
        onTap: _pickProductionDate,
        decoration: const InputDecoration(
          labelText: 'Production Date *',
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
      _readOnlyController('Unit Price', unitPriceController),
      _readOnlyController('Sewing Quantity', sewingQuantityController),
      _readOnlyController('Available Quantity', availableQuantityController),
      TextField(
        controller: quantity,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: 'Quantity *',
          errorText: _validationMessage,
        ),
        onChanged: (_) {
          _recalculateValue();
          _validateQuantity();
        },
      ),
      _readOnlyController('Production Value', productionValueController),
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
            onPressed: _isSubmitting ? null : () => context.go('/production'),
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
                : const Text('Save Production'),
          ),
        ],
      ),
    ],
  );

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
        if (value != null) context.read<ProductionBloc>().add(SelectPO(value));
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
          sewingQuantity = 0;
          availableQuantity = 0;
          sewingQuantityController.text = '0';
          availableQuantityController.text = '0';
        });
        if (value != null && poNo != null) {
          context.read<ProductionBloc>().add(LoadArticleColors(poNo!, value));
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
          context.read<ProductionBloc>().add(
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
  void _save() {
    if (_isSubmitting) return;
    final selectedPO = poNo;
    final selectedArticle = article;
    final selectedColor = color;
    final date = productionDate;
    if (date == null) {
      _snack('Please select a production date');
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
      _snack('Production quantity must be greater than zero');
      return;
    }
    if (qty > availableQuantity) {
      _snack('Production quantity must be between 1 and $availableQuantity');
      return;
    }
    setState(() => _isSubmitting = true);
    final item = ProductionEntity(
      id: widget.initialItem?.id,
      sl: widget.initialItem?.sl ?? DateTime.now().millisecondsSinceEpoch,
      voucherNo: voucher.text.trim(),
      productionDate: date,
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
      productionValue: productionValue,
      sewingQuantity: sewingQuantity,
      remarks: remarks.text.trim(),
      source: widget.initialItem?.source,
      syncStatus: widget.initialItem?.syncStatus,
      createdAt: widget.initialItem?.createdAt,
    );
    context.read<ProductionBloc>().add(
      widget.initialItem == null
          ? CreateProduction(item)
          : UpdateProduction(item),
    );
  }
}

