import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flag/flag.dart';

class LanguageData {
  final String code;
  final String? countryCode; // For EasyLocalization if needed
  final String flagCode;
  final String nativeName;

  LanguageData({
    required this.code,
    this.countryCode,
    required this.flagCode,
    required this.nativeName,
  });
}

class LanguageSelectorDialog extends StatelessWidget {
  LanguageSelectorDialog({super.key});

  final List<LanguageData> languages = [
    LanguageData(code: 'ar', flagCode: 'AE', nativeName: 'العربية'),
    LanguageData(code: 'bg', flagCode: 'BG', nativeName: 'БЪЛГАРСКИ'),
    LanguageData(code: 'cs', flagCode: 'CZ', nativeName: 'ČEŠTINA'),
    LanguageData(code: 'da', flagCode: 'DK', nativeName: 'DANSK'),
    LanguageData(code: 'de', flagCode: 'DE', nativeName: 'DEUTSCH'),
    LanguageData(code: 'el', flagCode: 'GR', nativeName: 'ΕΛΛΗΝΙΚΑ'),
    LanguageData(code: 'en', flagCode: 'GB', nativeName: 'ENGLISH'),
    LanguageData(code: 'es', flagCode: 'ES', nativeName: 'ESPAÑOL'),
    LanguageData(code: 'et', flagCode: 'EE', nativeName: 'EESTI'),
    LanguageData(code: 'fi', flagCode: 'FI', nativeName: 'SUOMI'),
    LanguageData(code: 'fr', flagCode: 'FR', nativeName: 'FRANÇAIS'),
    LanguageData(code: 'he', flagCode: 'IL', nativeName: 'עברית'), // Note: sometimes 'iw'
    LanguageData(code: 'hi', flagCode: 'IN', nativeName: 'हिंदी'),
    LanguageData(code: 'hu', flagCode: 'HU', nativeName: 'MAGYAR'),
    LanguageData(code: 'id', flagCode: 'ID', nativeName: 'INDONESIA'),
    LanguageData(code: 'it', flagCode: 'IT', nativeName: 'ITALIANO'),
    LanguageData(code: 'ja', flagCode: 'JP', nativeName: '日本語'),
    LanguageData(code: 'ko', flagCode: 'KR', nativeName: '한국어'),
    LanguageData(code: 'lt', flagCode: 'LT', nativeName: 'LIETUVIŲ'),
    LanguageData(code: 'lv', flagCode: 'LV', nativeName: 'LATVIEŠU'),
    LanguageData(code: 'no', flagCode: 'NO', nativeName: 'BOKMÅL'),
    LanguageData(code: 'nl', flagCode: 'NL', nativeName: 'NEDERLANDS'),
    LanguageData(code: 'pl', flagCode: 'PL', nativeName: 'POLSKI'),
    LanguageData(code: 'pt', flagCode: 'BR', nativeName: 'PORTUGUÊS'),
    LanguageData(code: 'ro', flagCode: 'RO', nativeName: 'ROMÂNĂ'),
    LanguageData(code: 'ru', flagCode: 'RU', nativeName: 'РУССКИЙ'),
    LanguageData(code: 'sk', flagCode: 'SK', nativeName: 'SLOVENČINA'),
    LanguageData(code: 'sl', flagCode: 'SI', nativeName: 'SLOVENŠČINA'),
    LanguageData(code: 'sv', flagCode: 'SE', nativeName: 'SVENSKA'),
    LanguageData(code: 'th', flagCode: 'TH', nativeName: 'ไทย'),
    LanguageData(code: 'tr', flagCode: 'TR', nativeName: 'TÜRKÇE'),
    LanguageData(code: 'uk', flagCode: 'UA', nativeName: 'УКРАЇНСЬКА'),
    LanguageData(code: 'vi', flagCode: 'VN', nativeName: 'TIẾNG VIỆT'),
    LanguageData(code: 'zh', flagCode: 'CN', nativeName: '中文'),
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.language, color: Colors.white, size: 28),
                    SizedBox(width: 10),
                    Text(
                      'Select Language',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Grid
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 150,
                  mainAxisSpacing: 15,
                  crossAxisSpacing: 15,
                  childAspectRatio: 1.0,
                ),
                itemCount: languages.length,
                itemBuilder: (context, index) {
                  final lang = languages[index];
                  final isSelected = context.locale.languageCode == lang.code;

                  return InkWell(
                    onTap: () {
                      context.setLocale(Locale(lang.code, lang.countryCode));
                      Navigator.of(context).pop();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white.withOpacity(0.15) : Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? Colors.cyanAccent : Colors.white.withOpacity(0.05),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Flag.fromString(
                              lang.flagCode,
                              height: 30,
                              width: 40,
                              fit: BoxFit.cover,
                              replacement: const Icon(Icons.error, color: Colors.white54),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            lang.nativeName.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
