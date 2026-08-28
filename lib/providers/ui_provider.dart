import 'package:flutter/foundation.dart';

/// Provider for global UI state (theme, navigation, etc.)

class UiProvider extends ChangeNotifier {
  int _currentTabIndex = 0;
  bool _isDarkMode = false;

  int get currentTabIndex => _currentTabIndex;
  bool get isDarkMode => _isDarkMode;

  void setTabIndex(int index) {
    _currentTabIndex = index;
    notifyListeners();
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}