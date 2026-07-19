import 'package:flutter/material.dart';

/// App language state. 'ar' (default), 'ckb' (Kurdish Sorani), 'en'.
/// Both ar and ckb render Right-To-Left.
class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('ar');
  Locale get locale => _locale;

  static bool isRtl(Locale l) => l.languageCode == 'ar' || l.languageCode == 'ckb';

  void setLocale(String code) {
    if (!const ['ar', 'ckb', 'en'].contains(code)) return;
    _locale = Locale(code);
    notifyListeners();
  }
}
