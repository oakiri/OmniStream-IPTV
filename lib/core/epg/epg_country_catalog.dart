class EpgCountryEntry {
  final String code; // ISO 3166-1 alpha-2
  final String name;

  const EpgCountryEntry(this.code, this.name);
}

/// Country catalog for iptv-epg.org.
/// URL pattern: https://iptv-epg.org/files/epg-<cc>.xml.gz
class EpgCountryCatalog {
  static const String _base = 'https://iptv-epg.org/files/';

  /// Primary list (based on the user's provided list).
  static const List<EpgCountryEntry> countries = [
    EpgCountryEntry('AL','Albania'),
    EpgCountryEntry('AR','Argentina'),
    EpgCountryEntry('AM','Armenia'),
    EpgCountryEntry('AU','Australia'),
    EpgCountryEntry('AT','Austria'),
    EpgCountryEntry('BY','Belarus'),
    EpgCountryEntry('BE','Belgium'),
    EpgCountryEntry('BO','Bolivia'),
    EpgCountryEntry('BA','Bosnia & Herzegovina'),
    EpgCountryEntry('BR','Brazil'),
    EpgCountryEntry('BG','Bulgaria'),
    EpgCountryEntry('CA','Canada'),
    EpgCountryEntry('CL','Chile'),
    EpgCountryEntry('CO','Colombia'),
    EpgCountryEntry('CR','Costa Rica'),
    EpgCountryEntry('HR','Croatia'),
    EpgCountryEntry('CZ','Czech Republic'),
    EpgCountryEntry('DK','Denmark'),
    EpgCountryEntry('DO','Dominican Republic'),
    EpgCountryEntry('EC','Ecuador'),
    EpgCountryEntry('EG','Egypt'),
    EpgCountryEntry('SV','El Salvador'),
    EpgCountryEntry('FI','Finland'),
    EpgCountryEntry('FR','France'),
    EpgCountryEntry('GE','Georgia'),
    EpgCountryEntry('DE','Germany'),
    EpgCountryEntry('GH','Ghana'),
    EpgCountryEntry('GR','Greece'),
    EpgCountryEntry('GT','Guatemala'),
    EpgCountryEntry('HN','Honduras'),
    EpgCountryEntry('HK','Hong Kong'),
    EpgCountryEntry('HU','Hungary'),
    EpgCountryEntry('IS','Iceland'),
    EpgCountryEntry('IN','India'),
    EpgCountryEntry('ID','Indonesia'),
    EpgCountryEntry('IL','Israel'),
    EpgCountryEntry('IT','Italy'),
    EpgCountryEntry('JP','Japan'),
    EpgCountryEntry('LV','Latvia'),
    EpgCountryEntry('LB','Lebanon'),
    EpgCountryEntry('LT','Lithuania'),
    EpgCountryEntry('LU','Luxembourg'),
    EpgCountryEntry('MK','Macedonia'),
    EpgCountryEntry('MY','Malaysia'),
    EpgCountryEntry('MT','Malta'),
    EpgCountryEntry('MX','Mexico'),
    EpgCountryEntry('ME','Montenegro'),
    EpgCountryEntry('NL','Netherlands'),
    EpgCountryEntry('NZ','New Zealand'),
    EpgCountryEntry('NI','Nicaragua'),
    EpgCountryEntry('NG','Nigeria'),
    EpgCountryEntry('NO','Norway'),
    EpgCountryEntry('PA','Panama'),
    EpgCountryEntry('PY','Paraguay'),
    EpgCountryEntry('PE','Peru'),
    EpgCountryEntry('PH','Philippines'),
    EpgCountryEntry('PL','Poland'),
    EpgCountryEntry('PT','Portugal'),
    EpgCountryEntry('RO','Romania'),
    EpgCountryEntry('RU','Russia'),
    EpgCountryEntry('SA','Saudi Arabia'),
    EpgCountryEntry('RS','Serbia'),
    EpgCountryEntry('SG','Singapore'),
    EpgCountryEntry('SI','Slovenia'),
    EpgCountryEntry('ZA','South Africa'),
    EpgCountryEntry('KR','South Korea'),
    EpgCountryEntry('ES','Spain'),
    EpgCountryEntry('SE','Sweden'),
    EpgCountryEntry('CH','Switzerland'),
    EpgCountryEntry('TW','Taiwan'),
    EpgCountryEntry('TH','Thailand'),
    EpgCountryEntry('TR','Turkey'),
    EpgCountryEntry('UG','Uganda'),
    EpgCountryEntry('UA','Ukraine'),
    EpgCountryEntry('AE','United Arab Emirates'),
    EpgCountryEntry('GB','United Kingdom'),
    EpgCountryEntry('US','United States'),
    EpgCountryEntry('UY','Uruguay'),
    EpgCountryEntry('VE','Venezuela'),
    EpgCountryEntry('VN','Vietnam'),
    EpgCountryEntry('ZW','Zimbabwe'),
  ];

  static bool supports(String code) {
    final cc = code.trim().toUpperCase();
    return countries.any((c) => c.code == cc);
  }

  static String normalizeFallback(String? code) {
    final cc = (code ?? '').trim().toUpperCase();
    if (cc.isEmpty) return 'ES';
    if (supports(cc)) return cc;
    return 'ES';
  }

  static Uri buildUri({
    required String countryCode,
    required bool preferGzip,
  }) {
    final cc = normalizeFallback(countryCode).toLowerCase();
    final path = 'epg-$cc.xml${preferGzip ? '.gz' : ''}';
    return Uri.parse('$_base$path');
  }
}
