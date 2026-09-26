/// ============================================================================
/// ফাইল: lib/presentation/screens/admin/demo_data_screen.dart
/// স্তর: Presentation Screen | মডিউল: ERP Common
/// উদ্দেশ্য: ERP Common মডিউলের user interface, input, filter ও user interaction উপস্থাপন করে।
/// প্রধান অংশ: DemoDataScreen, _DemoDataScreenState
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:flutter/material.dart';
import '../../../data/services/demo_data_seeder.dart';

class DemoDataScreen extends StatefulWidget {
  const DemoDataScreen({super.key});
  @override
  State<DemoDataScreen> createState() => _DemoDataScreenState();
}

class _DemoDataScreenState extends State<DemoDataScreen> {
  final _seeder = DemoDataSeeder();
  int _count = 3000;
  bool _running = false;
  String _status = 'Ready';
  String? _collection;
  int _done = 0;
  int _total = 3000;

  Future<bool> _confirm(String message) async => await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Confirm demo data action'),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Continue')),
      ],
    ),
  ) ?? false;

  Future<void> _seed() async {
    if (_running) return;
    if (!await _confirm('Generate $_count demo records per department?\n\nThis creates ${_count * DemoDataSeeder.collections.length} Firestore documents.')) return;
    setState(() { _running = true; _status = 'Starting...'; _collection = null; _done = 0; _total = _count; });
    try {
      await _seeder.seed(count: _count, onProgress: (collection, done, total) {
        if (!mounted) return;
        setState(() { _collection = collection; _done = done; _total = total; _status = 'Loading $collection: $done / $total'; });
      });
      if (mounted) setState(() => _status = 'Completed successfully');
    } catch (error) {
      if (mounted) setState(() => _status = 'Failed: $error');
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  Future<void> _clear() async {
    if (_running) return;
    if (!await _confirm('Delete only records created by this demo seeder?\n\nNormal records are protected because deletion uses the demoSeed marker.')) return;
    setState(() { _running = true; _status = 'Deleting demo data...'; });
    try {
      final deleted = await _seeder.clear(onProgress: (collection, done) {
        if (mounted) setState(() => _status = 'Deleting $collection: $done removed');
      });
      if (mounted) setState(() => _status = 'Deleted $deleted demo documents');
    } catch (error) {
      if (mounted) setState(() => _status = 'Failed: $error');
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = _total == 0 ? 0.0 : _done / _total;
    return Scaffold(
      appBar: AppBar(title: const Text('Demo Data Seeder')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: ListView(padding: const EdgeInsets.all(24), children: [
            Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Test Data Generator', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Generate clearly-marked test records across all ERP departments.'),
              const SizedBox(height: 20),
              DropdownButtonFormField<int>(
                initialValue: _count,
                decoration: const InputDecoration(labelText: 'Records per department'),
                items: const [
                  DropdownMenuItem(value: 3000, child: Text('3,000 records / department')),
                  DropdownMenuItem(value: 4000, child: Text('4,000 records / department')),
                  DropdownMenuItem(value: 5000, child: Text('5,000 records / department')),
                ],
                onChanged: _running ? null : (value) => setState(() => _count = value ?? 3000),
              ),
              const SizedBox(height: 16),
              Wrap(spacing: 12, runSpacing: 12, children: [
                FilledButton.icon(onPressed: _running ? null : _seed, icon: const Icon(Icons.cloud_upload), label: Text('Load $_count Demo Data')),
                OutlinedButton.icon(onPressed: _running ? null : _clear, icon: const Icon(Icons.delete_sweep), label: const Text('Delete Demo Data')),
              ]),
              const SizedBox(height: 24),
              Text(_status),
              if (_running) ...[
                const SizedBox(height: 10), LinearProgressIndicator(value: progress),
                if (_collection != null) ...[const SizedBox(height: 8), Text('$_collection: $_done / $_total')],
              ],
            ]))),
            const SizedBox(height: 16),
            const Card(child: Padding(padding: EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Included departments', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('Master LC • Purchase Orders • Cutting • Sewing • Production • Issue • Export'),
              SizedBox(height: 12),
              Text('Safety: demo records carry a unique demoSeed marker. Delete Demo Data removes only those records.'),
              SizedBox(height: 8),
              Text('For large runs, use a staging Firebase project or local emulator to avoid unnecessary production writes/costs.'),
            ]))),
          ]),
        ),
      ),
    );
  }
}
