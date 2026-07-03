/// Simple localization strings for English and Bahasa Malaysia.
/// Add new strings here and reference them via AppStrings.of(context).
class AppStrings {
  final String languageCode;
  const AppStrings._(this.languageCode);

  static const AppStrings en = AppStrings._('en');
  static const AppStrings ms = AppStrings._('ms');

  static AppStrings fromCode(String code) =>
      code == 'ms' ? ms : en;

  // ── Bottom Navigation ─────────────────────────────────────────────
  String get navHome         => _t('Home',     'Utama');
  String get navSearch       => _t('Search',   'Carian');
  String get navBudget       => _t('Budget',   'Belanjawan');
  String get navProfile      => _t('Profile',  'Profil');

  // ── Profile Tab ───────────────────────────────────────────────────
  String get signedIn        => _t('Signed In',          'Sudah Log Masuk');
  String get sectionAccount  => _t('Account',            'Akaun');
  String get sectionPrefs    => _t('Preferences',        'Keutamaan');
  String get sectionSupport  => _t('Support',            'Sokongan');
  String get accountSettings => _t('Account Settings',  'Tetapan Akaun');
  String get favorites       => _t('Favorites',          'Kegemaran');
  String get notifications   => _t('Notifications',      'Pemberitahuan');
  String get language        => _t('Language',           'Bahasa');
  String get about           => _t('About SmartShopper', 'Tentang SmartShopper');
  String get helpCenter      => _t('Help Center',         'Pusat Bantuan');
  String get contactUs       => _t('Contact Us',          'Hubungi Kami');
  String get faq             => _t('FAQ',                 'Soalan Lazim');
  String get sendMessage     => _t('Send Message',        'Hantar Mesej');
  String get emailUs         => _t('Email Us',            'Emel Kami');
  String get callUs          => _t('Call Us',             'Hubungi Kami');
  String get signOut         => _t('Sign Out',            'Log Keluar');
  String get lightMode       => _t('Light Mode',         'Mod Terang');
  String get manual          => _t('Manual',             'Manual');
  String get selectLanguage  => _t('Select Language',    'Pilih Bahasa');
  String get english         => _t('English',            'Bahasa Inggeris');
  String get bahasaMalaysia  => _t('Bahasa Malaysia',    'Bahasa Malaysia');

  // ── Home Tab ──────────────────────────────────────────────────────
  String get goodMorning     => _t('Good Morning',       'Selamat Pagi');
  String get goodAfternoon   => _t('Good Afternoon',     'Selamat Tengah Hari');
  String get goodEvening     => _t('Good Evening',       'Selamat Petang');
  String get dealsForYou     => _t('Deals For You',      'Tawaran Untuk Anda');
  String get viewAll         => _t('View All',           'Lihat Semua');
  String get smartTips       => _t('Smart Saving Tips',  'Tips Jimat Pintar');

  // ── Search Tab ────────────────────────────────────────────────────
  String get searchHint      => _t('Search Milo, Drinks, Noodles…', 'Cari Milo, Minuman, Mi…');
  String get recentSearches  => _t('Recent Searches',   'Carian Terkini');
  String get popularSearches => _t('Popular Searches',  'Carian Popular');
  String get trySearchingFor => _t('Try Searching For', 'Cuba Cari');
  String get byCategory      => _t('By Category',       'Mengikut Kategori');
  String get byBrand         => _t('By Brand',          'Mengikut Jenama');
  String get bestPrice       => _t('BEST PRICE',        'HARGA TERBAIK');

  // ── Budget Tab ────────────────────────────────────────────────────
  String get budgetPlanning  => _t('Budget Planning',   'Perancangan Belanjawan');
  String get monthlyLimit    => _t('Monthly Limit',     'Had Bulanan');
  String get totalSpent      => _t('Total Spent',       'Jumlah Dibelanjakan');
  String get remaining       => _t('Remaining',         'Baki');

  // ── General ───────────────────────────────────────────────────────
  String get loading         => _t('Loading…',          'Memuatkan…');
  String get retry           => _t('Retry',             'Cuba Lagi');
  String get cancel          => _t('Cancel',            'Batal');
  String get save            => _t('Save',              'Simpan');
  String get confirm         => _t('Confirm',           'Sahkan');
  String get addToList       => _t('Add to List',       'Tambah ke Senarai');

  // ─── helper ───────────────────────────────────────────────────────
  String _t(String en, String ms) => languageCode == 'ms' ? ms : en;
}
