import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/issue_entity.dart';
import '../../blocs/issue/issue_bloc.dart';
import '../../blocs/issue/issue_event.dart';
import '../../blocs/issue/issue_state.dart';

/// PO-driven Issue (finished goods dispatch) entry form.
///
/// Flow: Issue Date → PO No (Production-filtered) → (auto-filled
/// Tag/Company/Project) → Article → Color → (auto Unit Price) → cumulative
/// Production + Available → Quantity → auto Issue Value → Save.
class IssueFormScreen extends StatefulWidget {
  const IssueFormScreen({super.key, this.initialItem});
  final IssueEntity? initialItem;

  @override
  State<IssueFormScreen> createState() => _IssueFormScreenState();
}

class _IssueFormScreenState extends State<IssueFormScreen> {
  static const _entryPersons = [
    'Admin',
    'Supervisor',
    'Operator',
    'Store Keeper',
  ];

  bool _isSubmitting = false;
  final voucher = TextEditingController();
  final factory = TextEditingController();
  final issueDateController = TextEditingController();
  final unitPriceController = TextEditingController(text: '0');
  final productionQuantityController = TextEditingController(text: '0');
  final availableQuantityController = TextEditingController(text: '0');
  final issueValueController = TextEditingController(text: '0');
  final quantity = TextEditingController();
  final entryPerson = TextEditingController();
  final remarks = TextEditingController();

  String? poNo, article, color;
  DateTime? issueDate;
  String tagNo = '', company = '', project = '';
  List<String> poNos = [], articles = [], colors = [];
  int productionQuantity = 0, availableQuantity = 0;
  double unitPrice = 0, issueValue = 0;

  /// Live validation message from the BLoC (shown as the quantity field error).
  String? _validationMessage;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    issueDate = today;
    issueDateController.text = _formatDate(today);
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
      issueValue = item.issueValue;
      productionQuantity = item.productionQuantity;
      availableQuantity = 0;
      quantity.text = item.quantity.toString();
      issueDate = item.issueDate;
      issueDateController.text = _formatDate(item.issueDate);
      unitPriceController.text = _money(unitPrice);
      productionQuantityController.text = productionQuantity.toString();
      availableQuantityController.text = availableQuantity.toString();
      issueValueController.text = _money(issueValue);
      poNos = item.poNo.trim().isEmpty ? [] : [item.poNo.trim()];
      articles = item.article.trim().isEmpty ? [] : [item.article.trim()];
      colors = item.color.trim().isEmpty ? [] : [item.color.trim()];
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IssueBloc>().add(LoadPONoList());
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
      issueDateController,
      unitPriceController,
      productionQuantityController,
      availableQuantityController,
      issueValueController,
      quantity,
      entryPerson,
      remarks,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Suggested voucher: `ISS-YYYYMMDD-XXX` (still manually editable).
  String _suggestVoucher(DateTime date) {
    final stamp =
        '${date.year}'
        '${date.month.toString().padLeft(2, '0')}'
        '${date.day.toString().padLeft(2, '0')}';
    final millis = date.millisecondsSinceEpoch.toString();
    return '${AppConstants.issueVoucherPrefix}-$stamp-'
        '${millis.substring(millis.length - 3)}';
  }

  Future<void> _pickIssueDate() async {
    final today = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: issueDate ?? today,
      firstDate: DateTime(2020),
      lastDate: DateTime(today.year + 5, today.month, today.day),
    );
    if (selected == null || !mounted) return;
    setState(() {
      issueDate = selected;
      issueDateController.text = _formatDate(selected);
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
      issueValue = qty * unitPrice;
      issueValueController.text = _money(issueValue);
    });
  }

  /// Reloads cumulative Production + Available for the current PO line/date.
  void _refreshAvailability() {
    final date = issueDate;
    if (poNo == null || article == null || color == null || date == null) return;
    context.read<IssueBloc>().add(
      LoadAvailableQuantity(
        poTagNo: tagNo,
        poNo: poNo!,
        article: article!,
        color: color!,
        issueDate: date,
        excludeId: widget.initialItem?.id,
      ),
    );
    _validateQuantity();
  }

  void _validateQuantity() {
    final date = issueDate;
    if (poNo == null || article == null || color == null || date == null) return;
    context.read<IssueBloc>().add(
      ValidateIssue(
        poTagNo: tagNo,
        poNo: poNo!,
        article: article!,
        color: color!,
        quantity: int.tryParse(quantity.text) ?? 0,
        issueDate: date,
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
    final date = issueDate;
    if (date == null) {
      _snack('Please select an issue date');
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
      _snack('Issue quantity must be greater than zero');
      return;
    }
    if (qty > availableQuantity) {
      _snack('Issue quantity must be between 1 and $availableQuantity');
      return;
    }
    setState(() => _isSubmitting = true);
    final item = IssueEntity(
      id: widget.initialItem?.id,
      sl: widget.initialItem?.sl ?? DateTime.now().millisecondsSinceEpoch,
      voucherNo: voucher.text.trim(),
      issueDate: date,
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
      issueValue: issueValue,
      productionQuantity: productionQuantity,
      remarks: remarks.text.trim(),
      source: widget.initialItem?.source,
      syncStatus: widget.initialItem?.syncStatus,
      createdAt: widget.initialItem?.createdAt,
    );
    context.read<IssueBloc>().add(
      widget.initialItem == null ? CreateIssue(item) : UpdateIssue(item),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: IconButton(
        tooltip: 'Back to Issue List',
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.go('/issue'),
      ),
      title: Text(
        widget.initialItem == null ? 'New Issue Record' : 'Edit Issue Record',
      ),
    ),
    body: BlocListener<IssueBloc, IssueState>(
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
              context.read<IssueBloc>().add(SelectPO(match.first));
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
              productionQuantity = 0;
              availableQuantity = 0;
              productionQuantityController.text = '0';
              availableQuantityController.text = '0';
            }
          });
          if (article != null) {
            context.read<IssueBloc>().add(
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
            context.read<IssueBloc>().add(
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
            productionQuantity = state.productionQty;
            availableQuantity = state.availableQty;
            productionQuantityController.text = state.productionQty.toString();
            availableQuantityController.text = state.availableQty.toString();
          });
        }
        if (state is IssueValidationError) {
          setState(() => _validationMessage = state.message);
        }
        if (state is IssueValidationSuccess) {
          setState(() => _validationMessage = null);
        }
        if (state is IssueSuccess) {
          setState(() => _isSubmitting = false);
          _snack('Issue saved successfully!');
          Navigator.pop(context);
        }
        if (state is IssueError) {
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
        controller: issueDateController,
        readOnly: true,
        onTap: _pickIssueDate,
        decoration: const InputDecoration(
          labelText: 'Issue Date *',
          suffixIcon: Icon(Icons.calendar_today),
        ),
      ),
      TextField(
        controller: voucher,
        decoration: const InputDecoration(
          labelText: 'Voucher No. *',
          helperText: 'Format: ISS-YYYYMMDD-XXX',
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
      _readOnlyController('Production Quantity', productionQuantityController),
      _readOnlyController('Available Quantity', availableQuantityController),
      TextField(
        controller: quantity,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: 'Issue Quantity *',
          errorText: _validationMessage,
        ),
        onChanged: (_) {
          _recalculateValue();
          _validateQuantity();
        },
      ),
      _readOnlyController('Issue Value', issueValueController),
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
            onPressed: _isSubmitting ? null : () => context.go('/issue'),
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
                : const Text('Save Issue'),
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
        if (value != null) context.read<IssueBloc>().add(SelectPO(value));
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
          productionQuantity = 0;
          availableQuantity = 0;
          productionQuantityController.text = '0';
          availableQuantityController.text = '0';
        });
        if (value != null && poNo != null) {
          context.read<IssueBloc>().add(LoadArticleColors(poNo!, value));
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
          context.read<IssueBloc>().add(
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
