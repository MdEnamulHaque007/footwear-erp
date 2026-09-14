import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/master_lc_entity.dart';
import '../../blocs/master_lc/master_lc_bloc.dart';
import '../../blocs/master_lc/master_lc_event.dart';
import '../../blocs/master_lc/master_lc_state.dart';

class MasterLCFormScreen extends StatefulWidget {
  const MasterLCFormScreen({super.key, this.id, this.entity});
  final String? id;
  final MasterLCEntity? entity;

  @override
  State<MasterLCFormScreen> createState() => _MasterLCFormScreenState();
}

class _MasterLCFormScreenState extends State<MasterLCFormScreen> {
  // Controllers for each input field
  final TextEditingController tag = TextEditingController();
  final TextEditingController date = TextEditingController();
  final TextEditingController scNo = TextEditingController();
  final TextEditingController lcNo = TextEditingController();
  final TextEditingController ttNo = TextEditingController();
  final TextEditingController quantity = TextEditingController();
  final TextEditingController value = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;

  /// SRS: Project and Company are selected from predefined dropdown lists.
  String? _project;
  String? _company;
  List<String> _projects = [];
  List<String> _companies = [];

  @override
  void dispose() {
    for (final c in [
      tag,
      date,
      scNo,
      lcNo,
      ttNo,
      quantity,
      value,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final item = widget.entity;
    _selectedDate = item?.masterLcDate ?? DateTime.now();
    date.text = DateFormat('dd/MM/yyyy').format(_selectedDate!);
    if (item != null) {
      tag.text = item.tagNo;
      _project = item.project.trim().isEmpty ? null : item.project.trim();
      _company = item.company.trim().isEmpty ? null : item.company.trim();
      // Seed the option lists with the record's own values so the edit-mode
      // selection always has a matching DropdownMenuItem.
      if (_project != null) _projects = [_project!];
      if (_company != null) _companies = [_company!];
      scNo.text = item.scNo;
      lcNo.text = item.lcNo;
      ttNo.text = item.ttNo;
      quantity.text = NumberFormat('#,##0').format(item.masterLcQuantity);
      value.text = NumberFormat('#,##0.00').format(item.masterLcValue);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MasterLCBloc>().add(LoadPredefinedLists());
    });
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

  // Helper to build a TextFormField with common styling
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool requiredField = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    IconData? icon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label + (requiredField ? ' *' : ''),
        prefixIcon: icon != null ? Icon(icon) : null,
        border: const OutlineInputBorder(),
      ),
      validator: validator ??
          (requiredField
              ? (value) => (value == null || value.trim().isEmpty)
                  ? 'Please enter $label'
                  : null
              : null),
    );
  }

  Widget _dateField() => TextFormField(
        controller: date,
        readOnly: true,
        decoration: const InputDecoration(
          labelText: 'Master LC Date *',
          prefixIcon: Icon(Icons.calendar_today),
          border: OutlineInputBorder(),
        ),
        onTap: () async {
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
              date.text = DateFormat('dd/MM/yyyy').format(selected);
            });
          }
        },
        validator: (_) => _selectedDate == null ? 'Please select a date' : null,
      );

  /// SRS "predefined dropdown list" for Project.
  Widget _projectDropdown() {
    final items = _safeItems([..._projects, ...AppConstants.predefinedProjects]);
    return DropdownButtonFormField<String>(
      initialValue: _safeValue(_project, items),
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Project *',
        prefixIcon: Icon(Icons.business_center),
        border: OutlineInputBorder(),
      ),
      items: items
          .map((value) => DropdownMenuItem(value: value, child: Text(value)))
          .toList(),
      onChanged: (value) => setState(() => _project = value),
      validator: (value) =>
          (value == null || value.trim().isEmpty) ? 'Please select Project' : null,
    );
  }

  /// SRS "predefined dropdown list" for Company.
  Widget _companyDropdown() {
    final items = _safeItems([
      ..._companies,
      ...AppConstants.predefinedCompanies,
    ]);
    return DropdownButtonFormField<String>(
      initialValue: _safeValue(_company, items),
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Company *',
        prefixIcon: Icon(Icons.apartment),
        border: OutlineInputBorder(),
      ),
      items: items
          .map((value) => DropdownMenuItem(value: value, child: Text(value)))
          .toList(),
      onChanged: (value) => setState(() => _company = value),
      validator: (value) =>
          (value == null || value.trim().isEmpty) ? 'Please select Company' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MasterLCBloc, MasterLCState>(
      listener: (context, state) {
        if (state is PredefinedListsLoaded) {
          setState(() {
            _projects = state.projects;
            _companies = state.companies;
            // Guard against a stale edit-mode selection.
            _project = _safeValue(_project, _safeItems(_projects));
            _company = _safeValue(_company, _safeItems(_companies));
          });
        } else if (state is MasterLCSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
          Navigator.of(context).pop();
        } else if (state is MasterLCError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Scaffold(
      appBar: AppBar(title: const Text('New Master LC')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _dateField(),
              const SizedBox(height: 16),
              _buildTextField(
                controller: tag,
                label: 'Tag No.',
                requiredField: true,
                icon: Icons.label,
              ),
              const SizedBox(height: 16),
              _projectDropdown(),
              const SizedBox(height: 16),
              _companyDropdown(),
              const SizedBox(height: 16),
              _buildTextField(
                controller: scNo,
                label: 'SC No.',
                icon: Icons.confirmation_number,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: lcNo,
                label: 'LC No.',
                icon: Icons.confirmation_number_outlined,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: ttNo,
                label: 'TT No.',
                icon: Icons.attach_money,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: quantity,
                label: 'Quantity',
                requiredField: true,
                keyboardType: TextInputType.number,
                icon: Icons.confirmation_number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter Quantity';
                  }
                  if (int.tryParse(value.replaceAll(',', '')) == null) {
                    return 'Enter a valid integer';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: value,
                label: 'LC Value',
                requiredField: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                icon: Icons.attach_money,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter LC Value';
                  }
                  if (double.tryParse(value.replaceAll(',', '')) == null) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    final item = MasterLCEntity(
                      id: widget.id ?? widget.entity?.id,
                      // SRS Rule 1: the Sl. is auto-generated by the repository
                      // inside the create transaction. 0 means "not yet
                      // assigned"; the persisted value is preserved on update.
                      sl: widget.entity?.sl ?? 0,
                      masterLcDate: _selectedDate!,
                      tagNo: tag.text.trim(),
                      project: _project?.trim() ?? '',
                      company: _company?.trim() ?? '',
                      scNo: scNo.text.trim(),
                      lcNo: lcNo.text.trim(),
                      ttNo: ttNo.text.trim(),
                      masterLcQuantity: int.parse(
                        quantity.text.replaceAll(',', ''),
                      ),
                      masterLcValue: double.parse(
                        value.text.replaceAll(',', '').replaceAll('\$', ''),
                      ),
                    );
                    context.read<MasterLCBloc>().add(
                      widget.id == null && widget.entity == null
                          ? CreateMasterLC(item)
                          : UpdateMasterLC(item),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please fix errors before saving')),
                    );
                  }
                },
                child: const Text('Save Master LC'),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
