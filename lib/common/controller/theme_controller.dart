import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_crm/common/constant/color_constant_dark_mode.dart';
import 'package:field_crm/common/controller/local_storage_provider.dart';

// --- Theme State & Notifier ---

enum AppThemeMode { light, dark, system }

final themeProvider = StateNotifierProvider<ThemeController, AppThemeMode>((ref) {
  final storage = ref.read(localStorageProvider);
  return ThemeController(storage);
});

class ThemeController extends StateNotifier<AppThemeMode> {
  static const String _themeKey = 'app_theme_mode';
  final dynamic _storage;

  ThemeController(this._storage) : super(AppThemeMode.system) {
    _loadTheme();
  }

  void _loadTheme() {
    final savedMode = _storage.get(_themeKey) as int?;
    if (savedMode != null) {
      if (savedMode == 0) state = AppThemeMode.light;
      if (savedMode == 1) state = AppThemeMode.dark;
      if (savedMode == 2) state = AppThemeMode.system;
    }
  }

  void setTheme(AppThemeMode mode) {
    state = mode;
    int saveVal = mode == AppThemeMode.light ? 0 : mode == AppThemeMode.dark ? 1 : 2;
    _storage.put(_themeKey, saveVal);
  }
}

// Global active theme palette reference to bridge the static legacy code
AppColorsTheme currentTheme = AppColorConstant.light;
