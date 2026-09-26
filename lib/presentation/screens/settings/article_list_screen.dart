/// ============================================================================
/// ফাইল: lib/presentation/screens/settings/article_list_screen.dart
/// স্তর: Presentation Screen | মডিউল: Settings
/// উদ্দেশ্য: Settings মডিউলের user interface, input, filter ও user interaction উপস্থাপন করে।
/// প্রধান অংশ: ArticleListScreen, _ArticleListScreenState, _AdminOnlyMessage
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/color_palette.dart';
import '../../../domain/entities/settings/business_settings_entity.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/settings/settings_bloc.dart';
import '../../blocs/settings/settings_event.dart';
import '../../blocs/settings/settings_state.dart';
import '../../widgets/app_drawer.dart';

class ArticleListScreen extends StatefulWidget {
  const ArticleListScreen({super.key});

  @override
  State<ArticleListScreen> createState() => _ArticleListScreenState();
}

class _ArticleListScreenState extends State<ArticleListScreen> {
  final _articleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SettingsBloc>().add(const LoadBusinessSettings());
      }
    });
  }

  @override
  void dispose() {
    _articleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    drawer: const AppDrawer(),
    appBar: AppBar(
      leadingWidth: 96,
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back),
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/settings'),
          ),
          Builder(
            builder: (drawerContext) => IconButton(
              tooltip: 'Menu',
              icon: const Icon(Icons.menu_rounded),
              onPressed: () => Scaffold.of(drawerContext).openDrawer(),
            ),
          ),
        ],
      ),
      title: const Text('Article Master'),
    ),
    body: BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! Authenticated || !authState.user.isAdmin) {
          return const _AdminOnlyMessage();
        }
        return BlocConsumer<SettingsBloc, SettingsState>(
          listener: (context, state) {
            if (state is SettingsSaved || state is SettingsError) {
              final message = state is SettingsSaved
                  ? state.message
                  : (state as SettingsError).message;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(message)));
            }
          },
          builder: (context, state) {
            if (state is SettingsLoading || state is SettingsInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is SettingsError) return _retry();
            if (state is! BusinessSettingsLoaded) {
              return const SizedBox.shrink();
            }
            return _content(state.entity);
          },
        );
      },
    ),
  );

  Widget _retry() => Center(
    child: FilledButton.icon(
      onPressed: () =>
          context.read<SettingsBloc>().add(const LoadBusinessSettings()),
      icon: const Icon(Icons.refresh),
      label: const Text('Try again'),
    ),
  );

  Widget _content(BusinessSettingsEntity settings) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
    children: [
      Text(
        'ARTICLE MASTER',
        style: const TextStyle(
          color: ColorPalette.muted,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
      const SizedBox(height: 8),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _articleController,
                  textCapitalization: TextCapitalization.words,
                  onSubmitted: (_) => _add(settings),
                  decoration: const InputDecoration(
                    labelText: 'New article name',
                    prefixIcon: Icon(Icons.inventory_2_outlined),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filled(
                tooltip: 'Add article',
                onPressed: () => _add(settings),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      if (settings.articleList.isEmpty)
        const Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('No articles added yet.')),
          ),
        )
      else
        Card(
          child: Column(
            children: [
              for (
                var index = 0;
                index < settings.articleList.length;
                index++
              ) ...[
                ListTile(
                  leading: const Icon(
                    Icons.inventory_2_outlined,
                    color: ColorPalette.primary,
                  ),
                  title: Text(settings.articleList[index]),
                  trailing: IconButton(
                    tooltip: 'Delete article',
                    icon: const Icon(Icons.delete_outline),
                    color: ColorPalette.error,
                    onPressed: () =>
                        _confirmDelete(settings, settings.articleList[index]),
                  ),
                ),
                if (index < settings.articleList.length - 1)
                  const Divider(height: 1),
              ],
            ],
          ),
        ),
    ],
  );

  void _add(BusinessSettingsEntity settings) {
    final article = _articleController.text.trim();
    if (article.isEmpty) {
      _message('Enter an article name first.');
      return;
    }
    final exists = settings.articleList.any(
      (item) => item.toLowerCase() == article.toLowerCase(),
    );
    if (exists) {
      _message('This article is already in the list.');
      return;
    }
    context.read<SettingsBloc>().add(
      UpdateArticleList([...settings.articleList, article]),
    );
    _articleController.clear();
  }

  Future<void> _confirmDelete(
    BusinessSettingsEntity settings,
    String article,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove article?'),
        content: Text('Remove "$article" from the article list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: ColorPalette.error),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    context.read<SettingsBloc>().add(
      UpdateArticleList(
        settings.articleList.where((item) => item != article).toList(),
      ),
    );
  }

  void _message(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _AdminOnlyMessage extends StatelessWidget {
  const _AdminOnlyMessage();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Text(
        'Only administrators can manage articles.',
        textAlign: TextAlign.center,
      ),
    ),
  );
}
