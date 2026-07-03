import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartshopper_mobile/config/app_strings.dart';

/// Holds the currently selected language code ('en' or 'ms').
class LanguageNotifier extends Notifier<String> {
  @override
  String build() => 'en'; // default English

  void setLanguage(String code) => state = code;
}

final languageProvider = NotifierProvider<LanguageNotifier, String>(
  LanguageNotifier.new,
);

/// Convenience provider: resolves the current AppStrings instance.
final stringsProvider = Provider<AppStrings>((ref) {
  final code = ref.watch(languageProvider);
  return AppStrings.fromCode(code);
});
