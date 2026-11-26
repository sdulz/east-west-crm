import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_crm/app/providers.dart';
import 'package:field_crm/common/controller/theme_controller.dart';

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
      (state.valueOrNull ?? const AppSettings()).copyWith(themeMode: mode),
    );
    try {
      final mapped = switch (mode) {
        ThemeMode.light => AppThemeMode.light,
        ThemeMode.dark => AppThemeMode.dark,
        ThemeMode.system => AppThemeMode.system,
      };
      ref.read(themeProvider.notifier).setTheme(mapped);
    } on Object {
      // Ignore if localStorageProvider is not active in isolated unit tests.
    }
    await ref.read(keyValueStoreProvider).put('theme_mode', mode.name);
  }

  Future<void> setLocale(Locale? locale) async {
    state = AsyncData(
      (state.valueOrNull ?? const AppSettings()).copyWith(locale: () => locale),
    );
    await ref
        .read(keyValueStoreProvider)
        .put('locale', locale?.languageCode ?? '');
  }
}
