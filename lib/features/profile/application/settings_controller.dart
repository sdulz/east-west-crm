import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_crm/app/providers.dart';

class AppSettings {
  const AppSettings({this.themeMode = ThemeMode.system, this.locale});
  final ThemeMode themeMode;
  final Locale? locale;

  AppSettings copyWith({ThemeMode? themeMode, Locale? Function()? locale}) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        locale: locale == null ? this.locale : locale(),
      );
}

final settingsControllerProvider =
    AsyncNotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
);

class SettingsController extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() async {
    final kv = ref.watch(keyValueStoreProvider);
    final theme = await kv.get('theme_mode');
    final locale = await kv.get('locale');
    return AppSettings(
      themeMode: ThemeMode.values.asNameMap()[theme] ?? ThemeMode.system,
      locale: locale == null || locale.isEmpty ? null : Locale(locale),
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = AsyncData(
      (state.value ?? const AppSettings()).copyWith(themeMode: mode),
    );
    await ref.read(keyValueStoreProvider).put('theme_mode', mode.name);
  }

  Future<void> setLocale(Locale? locale) async {
    state = AsyncData(
      (state.value ?? const AppSettings()).copyWith(locale: () => locale),
    );
    await ref
        .read(keyValueStoreProvider)
        .put('locale', locale?.languageCode ?? '');
  }
}
