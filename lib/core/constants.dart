/// Canonical value lists. Stored in Firestore as the `code`,
/// displayed via the localized label for the active language.
class Governorates {
  static const codes = [
    'baghdad','basra','nineveh','erbil','sulaymaniyah','duhok','kirkuk','anbar',
    'babil','karbala','najaf','wasit','maysan','dhi_qar','muthanna','qadisiyyah',
    'diyala','salah_al_din','halabja',
  ];
  static const _labels = {
    'baghdad':      {'ar': 'بغداد', 'ckb': 'بەغدا', 'en': 'Baghdad'},
    'basra':        {'ar': 'البصرة', 'ckb': 'بەسرە', 'en': 'Basra'},
    'nineveh':      {'ar': 'نينوى', 'ckb': 'نەینەوا', 'en': 'Nineveh'},
    'erbil':        {'ar': 'أربيل', 'ckb': 'هەولێر', 'en': 'Erbil'},
    'sulaymaniyah': {'ar': 'السليمانية', 'ckb': 'سلێمانی', 'en': 'Sulaymaniyah'},
    'duhok':        {'ar': 'دهوك', 'ckb': 'دهۆک', 'en': 'Duhok'},
    'kirkuk':       {'ar': 'كركوك', 'ckb': 'کەرکووک', 'en': 'Kirkuk'},
    'anbar':        {'ar': 'الأنبار', 'ckb': 'ئەنبار', 'en': 'Anbar'},
    'babil':        {'ar': 'بابل', 'ckb': 'بابل', 'en': 'Babil'},
    'karbala':      {'ar': 'كربلاء', 'ckb': 'کەربەلا', 'en': 'Karbala'},
    'najaf':        {'ar': 'النجف', 'ckb': 'نەجەف', 'en': 'Najaf'},
    'wasit':        {'ar': 'واسط', 'ckb': 'واست', 'en': 'Wasit'},
    'maysan':       {'ar': 'ميسان', 'ckb': 'مەیسان', 'en': 'Maysan'},
    'dhi_qar':      {'ar': 'ذي قار', 'ckb': 'زیقار', 'en': 'Dhi Qar'},
    'muthanna':     {'ar': 'المثنى', 'ckb': 'موسەننا', 'en': 'Muthanna'},
    'qadisiyyah':   {'ar': 'القادسية', 'ckb': 'قادسیە', 'en': 'Qadisiyyah'},
    'diyala':       {'ar': 'ديالى', 'ckb': 'دیالە', 'en': 'Diyala'},
    'salah_al_din': {'ar': 'صلاح الدين', 'ckb': 'سەڵاحەدین', 'en': 'Salah al-Din'},
    'halabja':      {'ar': 'حلبجة', 'ckb': 'هەڵەبجە', 'en': 'Halabja'},
  };
  static String label(String code, String lang) =>
      _labels[code]?[lang] ?? _labels[code]?['ar'] ?? code;
}

class Specializations {
  static const codes = [
    'personal_status','criminal','civil','commercial','labor','real_estate',
    'administrative','intellectual_property',
  ];
  static const _labels = {
    'personal_status':       {'ar': 'أحوال شخصية', 'ckb': 'باری کەسی', 'en': 'Personal Status'},
    'criminal':              {'ar': 'قانون جنائي', 'ckb': 'یاسای سزادان', 'en': 'Criminal Law'},
    'civil':                 {'ar': 'قانون مدني', 'ckb': 'یاسای مەدەنی', 'en': 'Civil Law'},
    'commercial':            {'ar': 'قانون تجاري', 'ckb': 'یاسای بازرگانی', 'en': 'Commercial Law'},
    'labor':                 {'ar': 'قانون العمل', 'ckb': 'یاسای کار', 'en': 'Labor Law'},
    'real_estate':           {'ar': 'عقارات', 'ckb': 'خانووبەرە', 'en': 'Real Estate'},
    'administrative':        {'ar': 'قانون إداري', 'ckb': 'یاسای کارگێڕی', 'en': 'Administrative Law'},
    'intellectual_property': {'ar': 'ملكية فكرية', 'ckb': 'موڵکی هزری', 'en': 'Intellectual Property'},
  };
  static String label(String code, String lang) =>
      _labels[code]?[lang] ?? _labels[code]?['ar'] ?? code;
}

/// Iraqi Dinar formatting: 1,250,000 د.ع
String formatIqd(num amount) {
  final s = amount.round().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return '$b د.ع';
}
