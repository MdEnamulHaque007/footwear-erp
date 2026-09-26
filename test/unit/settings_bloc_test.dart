/// ============================================================================
/// ফাইল: test/unit/settings_bloc_test.dart
/// স্তর: Test | মডিউল: Settings
/// উদ্দেশ্য: Settings Bloc Test অংশের প্রত্যাশিত আচরণ স্বয়ংক্রিয়ভাবে যাচাই করে এবং regression প্রতিরোধ করে।
/// প্রধান অংশ: _MemorySettingsRepository
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:footwear/domain/entities/settings/app_settings_entity.dart';
import 'package:footwear/domain/entities/settings/business_settings_entity.dart';
import 'package:footwear/domain/repositories/i_settings_repository.dart';
import 'package:footwear/domain/usecases/settings/get_app_settings_usecase.dart';
import 'package:footwear/domain/usecases/settings/get_business_settings_usecase.dart';
import 'package:footwear/domain/usecases/settings/save_app_settings_usecase.dart';
import 'package:footwear/domain/usecases/settings/save_business_settings_usecase.dart';
import 'package:footwear/presentation/blocs/settings/settings_bloc.dart';
import 'package:footwear/presentation/blocs/settings/settings_event.dart';
import 'package:footwear/presentation/blocs/settings/settings_state.dart';

void main() {
  late _MemorySettingsRepository repository;
  late SettingsBloc bloc;

  setUp(() {
    repository = _MemorySettingsRepository();
    bloc = SettingsBloc(
      getAppSettings: GetAppSettingsUseCase(repository),
      saveAppSettings: SaveAppSettingsUseCase(repository),
      getBusinessSettings: GetBusinessSettingsUseCase(repository),
      saveBusinessSettings: SaveBusinessSettingsUseCase(repository),
    );
  });

  tearDown(() => bloc.close());

  test('loads the persisted app settings', () async {
    repository.appSettings = const AppSettingsEntity(themeMode: 'dark');
    final states = <SettingsState>[];
    final subscription = bloc.stream.listen(states.add);

    bloc.add(const LoadAppSettings());
    await _settle();
    await subscription.cancel();

    expect(states, hasLength(2));
    expect(states.first, isA<SettingsLoading>());
    expect((states.last as AppSettingsLoaded).entity.themeMode, 'dark');
  });

  test('persists all notification preferences together', () async {
    final states = <SettingsState>[];
    final subscription = bloc.stream.listen(states.add);

    bloc.add(
      const UpdateNotifications(
        email: false,
        push: false,
        inApp: true,
        sound: false,
      ),
    );
    await _settle();
    await subscription.cancel();

    expect(repository.appSettings.emailNotifications, isFalse);
    expect(repository.appSettings.pushNotifications, isFalse);
    expect(repository.appSettings.inAppNotifications, isTrue);
    expect(repository.appSettings.soundAlerts, isFalse);
    expect(
      states.whereType<SettingsSaved>().single.message,
      'Notifications updated',
    );
    expect((states.last as AppSettingsLoaded).entity, repository.appSettings);
  });

  test(
    'updates the factory master list without changing other settings',
    () async {
      repository.businessSettings = const BusinessSettingsEntity(
        companyName: 'IALT Footwear Ltd.',
        projectList: ['Project X'],
        factoryList: ['Factory A'],
      );
      final states = <SettingsState>[];
      final subscription = bloc.stream.listen(states.add);

      bloc.add(const LoadBusinessSettings());
      await _settle();
      states.clear();
      bloc.add(const UpdateFactoryList(['Factory A', 'Factory B']));
      await _settle();
      await subscription.cancel();

      expect(repository.businessSettings.factoryList, [
        'Factory A',
        'Factory B',
      ]);
      expect(repository.businessSettings.projectList, ['Project X']);
      expect(
        states.whereType<SettingsSaved>().single.message,
        'Factory list updated',
      );
      expect(states.last, isA<BusinessSettingsLoaded>());
    },
  );

  test('reset restores defaults for both app and business settings', () async {
    repository.appSettings = const AppSettingsEntity(themeMode: 'dark');
    repository.businessSettings = const BusinessSettingsEntity(
      companyName: 'Custom Footwear',
      factoryList: ['Custom Factory'],
    );
    final states = <SettingsState>[];
    final subscription = bloc.stream.listen(states.add);

    bloc.add(const ResetToDefaults());
    await _settle();
    await subscription.cancel();

    expect(repository.appSettings, AppSettingsEntity.defaults());
    expect(repository.businessSettings, BusinessSettingsEntity.defaults());
    expect(states.whereType<SettingsReset>(), isNotEmpty);
    expect(
      states.whereType<SettingsSaved>().single.message,
      'Reset to defaults',
    );
  });
}

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 10));

class _MemorySettingsRepository implements ISettingsRepository {
  AppSettingsEntity appSettings = AppSettingsEntity.defaults();
  BusinessSettingsEntity businessSettings = BusinessSettingsEntity.defaults();

  @override
  Future<Either<String, AppSettingsEntity>> getAppSettings() async =>
      Right(appSettings);

  @override
  Future<Either<String, BusinessSettingsEntity>> getBusinessSettings() async =>
      Right(businessSettings);

  @override
  Future<Either<String, void>> saveAppSettings(AppSettingsEntity entity) async {
    appSettings = entity;
    return const Right(null);
  }

  @override
  Future<Either<String, void>> saveBusinessSettings(
    BusinessSettingsEntity entity,
  ) async {
    businessSettings = entity;
    return const Right(null);
  }
}
