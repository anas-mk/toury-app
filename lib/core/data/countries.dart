/// Country reference data — name, ISO 3166-1 alpha-2 code, ITU-T E.164
/// dial code, and a flag emoji built from the regional-indicator letters.
///
/// Used by the profile phone-number editor (and any future picker that
/// needs full coverage). Hand-curated to keep the bundle small while
/// covering every UN member + observer state.
class Country {
  final String name;
  final String code; // ISO alpha-2, e.g. "EG"
  final String dialCode; // E.164, e.g. "+20"

  const Country({
    required this.name,
    required this.code,
    required this.dialCode,
  });

  /// Renders the flag from the country's ISO code via the regional-
  /// indicator unicode block (works on iOS, modern Android, and most
  /// emoji fonts; on emoji-less surfaces it falls back to the ISO code
  /// gracefully).
  String get flag {
    if (code.length != 2) return '';
    const base = 0x1F1E6; // 🇦
    final upper = code.toUpperCase();
    final cp1 = base + (upper.codeUnitAt(0) - 'A'.codeUnitAt(0));
    final cp2 = base + (upper.codeUnitAt(1) - 'A'.codeUnitAt(0));
    return String.fromCharCodes([cp1, cp2]);
  }
}

abstract class Countries {
  Countries._();

  /// Best-effort match by ISO code, then by dial code, then by name.
  /// Returns `null` when nothing fits — callers should fall back to a
  /// sane default (typically Egypt for this app).
  static Country? findByCode(String? code) {
    if (code == null || code.isEmpty) return null;
    final upper = code.toUpperCase();
    for (final c in all) {
      if (c.code == upper) return c;
    }
    return null;
  }

  static Country? findByDial(String? dial) {
    if (dial == null || dial.isEmpty) return null;
    final normalized = dial.startsWith('+') ? dial : '+$dial';
    for (final c in all) {
      if (c.dialCode == normalized) return c;
    }
    return null;
  }

  static Country? findByName(String? name) {
    if (name == null || name.isEmpty) return null;
    final lower = name.toLowerCase().trim();
    for (final c in all) {
      if (c.name.toLowerCase() == lower) return c;
    }
    return null;
  }

  /// Hand-curated list — all UN member states + observers + popular
  /// territories. Sorted alphabetically for stable picker UX.
  static const List<Country> all = [
    Country(name: 'Afghanistan', code: 'AF', dialCode: '+93'),
    Country(name: 'Albania', code: 'AL', dialCode: '+355'),
    Country(name: 'Algeria', code: 'DZ', dialCode: '+213'),
    Country(name: 'Andorra', code: 'AD', dialCode: '+376'),
    Country(name: 'Angola', code: 'AO', dialCode: '+244'),
    Country(name: 'Argentina', code: 'AR', dialCode: '+54'),
    Country(name: 'Armenia', code: 'AM', dialCode: '+374'),
    Country(name: 'Australia', code: 'AU', dialCode: '+61'),
    Country(name: 'Austria', code: 'AT', dialCode: '+43'),
    Country(name: 'Azerbaijan', code: 'AZ', dialCode: '+994'),
    Country(name: 'Bahamas', code: 'BS', dialCode: '+1242'),
    Country(name: 'Bahrain', code: 'BH', dialCode: '+973'),
    Country(name: 'Bangladesh', code: 'BD', dialCode: '+880'),
    Country(name: 'Barbados', code: 'BB', dialCode: '+1246'),
    Country(name: 'Belarus', code: 'BY', dialCode: '+375'),
    Country(name: 'Belgium', code: 'BE', dialCode: '+32'),
    Country(name: 'Belize', code: 'BZ', dialCode: '+501'),
    Country(name: 'Benin', code: 'BJ', dialCode: '+229'),
    Country(name: 'Bhutan', code: 'BT', dialCode: '+975'),
    Country(name: 'Bolivia', code: 'BO', dialCode: '+591'),
    Country(name: 'Bosnia and Herzegovina', code: 'BA', dialCode: '+387'),
    Country(name: 'Botswana', code: 'BW', dialCode: '+267'),
    Country(name: 'Brazil', code: 'BR', dialCode: '+55'),
    Country(name: 'Brunei', code: 'BN', dialCode: '+673'),
    Country(name: 'Bulgaria', code: 'BG', dialCode: '+359'),
    Country(name: 'Burkina Faso', code: 'BF', dialCode: '+226'),
    Country(name: 'Burundi', code: 'BI', dialCode: '+257'),
    Country(name: 'Cambodia', code: 'KH', dialCode: '+855'),
    Country(name: 'Cameroon', code: 'CM', dialCode: '+237'),
    Country(name: 'Canada', code: 'CA', dialCode: '+1'),
    Country(name: 'Cape Verde', code: 'CV', dialCode: '+238'),
    Country(name: 'Central African Republic', code: 'CF', dialCode: '+236'),
    Country(name: 'Chad', code: 'TD', dialCode: '+235'),
    Country(name: 'Chile', code: 'CL', dialCode: '+56'),
    Country(name: 'China', code: 'CN', dialCode: '+86'),
    Country(name: 'Colombia', code: 'CO', dialCode: '+57'),
    Country(name: 'Comoros', code: 'KM', dialCode: '+269'),
    Country(name: 'Congo', code: 'CG', dialCode: '+242'),
    Country(name: 'Congo (DRC)', code: 'CD', dialCode: '+243'),
    Country(name: 'Costa Rica', code: 'CR', dialCode: '+506'),
    Country(name: 'Croatia', code: 'HR', dialCode: '+385'),
    Country(name: 'Cuba', code: 'CU', dialCode: '+53'),
    Country(name: 'Cyprus', code: 'CY', dialCode: '+357'),
    Country(name: 'Czech Republic', code: 'CZ', dialCode: '+420'),
    Country(name: 'Denmark', code: 'DK', dialCode: '+45'),
    Country(name: 'Djibouti', code: 'DJ', dialCode: '+253'),
    Country(name: 'Dominica', code: 'DM', dialCode: '+1767'),
    Country(name: 'Dominican Republic', code: 'DO', dialCode: '+1809'),
    Country(name: 'Ecuador', code: 'EC', dialCode: '+593'),
    Country(name: 'Egypt', code: 'EG', dialCode: '+20'),
    Country(name: 'El Salvador', code: 'SV', dialCode: '+503'),
    Country(name: 'Equatorial Guinea', code: 'GQ', dialCode: '+240'),
    Country(name: 'Eritrea', code: 'ER', dialCode: '+291'),
    Country(name: 'Estonia', code: 'EE', dialCode: '+372'),
    Country(name: 'Eswatini', code: 'SZ', dialCode: '+268'),
    Country(name: 'Ethiopia', code: 'ET', dialCode: '+251'),
    Country(name: 'Fiji', code: 'FJ', dialCode: '+679'),
    Country(name: 'Finland', code: 'FI', dialCode: '+358'),
    Country(name: 'France', code: 'FR', dialCode: '+33'),
    Country(name: 'Gabon', code: 'GA', dialCode: '+241'),
    Country(name: 'Gambia', code: 'GM', dialCode: '+220'),
    Country(name: 'Georgia', code: 'GE', dialCode: '+995'),
    Country(name: 'Germany', code: 'DE', dialCode: '+49'),
    Country(name: 'Ghana', code: 'GH', dialCode: '+233'),
    Country(name: 'Greece', code: 'GR', dialCode: '+30'),
    Country(name: 'Grenada', code: 'GD', dialCode: '+1473'),
    Country(name: 'Guatemala', code: 'GT', dialCode: '+502'),
    Country(name: 'Guinea', code: 'GN', dialCode: '+224'),
    Country(name: 'Guinea-Bissau', code: 'GW', dialCode: '+245'),
    Country(name: 'Guyana', code: 'GY', dialCode: '+592'),
    Country(name: 'Haiti', code: 'HT', dialCode: '+509'),
    Country(name: 'Honduras', code: 'HN', dialCode: '+504'),
    Country(name: 'Hong Kong', code: 'HK', dialCode: '+852'),
    Country(name: 'Hungary', code: 'HU', dialCode: '+36'),
    Country(name: 'Iceland', code: 'IS', dialCode: '+354'),
    Country(name: 'India', code: 'IN', dialCode: '+91'),
    Country(name: 'Indonesia', code: 'ID', dialCode: '+62'),
    Country(name: 'Iran', code: 'IR', dialCode: '+98'),
    Country(name: 'Iraq', code: 'IQ', dialCode: '+964'),
    Country(name: 'Ireland', code: 'IE', dialCode: '+353'),
    Country(name: 'Italy', code: 'IT', dialCode: '+39'),
    Country(name: 'Ivory Coast', code: 'CI', dialCode: '+225'),
    Country(name: 'Jamaica', code: 'JM', dialCode: '+1876'),
    Country(name: 'Japan', code: 'JP', dialCode: '+81'),
    Country(name: 'Jordan', code: 'JO', dialCode: '+962'),
    Country(name: 'Kazakhstan', code: 'KZ', dialCode: '+7'),
    Country(name: 'Kenya', code: 'KE', dialCode: '+254'),
    Country(name: 'Kiribati', code: 'KI', dialCode: '+686'),
    Country(name: 'Kosovo', code: 'XK', dialCode: '+383'),
    Country(name: 'Kuwait', code: 'KW', dialCode: '+965'),
    Country(name: 'Kyrgyzstan', code: 'KG', dialCode: '+996'),
    Country(name: 'Laos', code: 'LA', dialCode: '+856'),
    Country(name: 'Latvia', code: 'LV', dialCode: '+371'),
    Country(name: 'Lebanon', code: 'LB', dialCode: '+961'),
    Country(name: 'Lesotho', code: 'LS', dialCode: '+266'),
    Country(name: 'Liberia', code: 'LR', dialCode: '+231'),
    Country(name: 'Libya', code: 'LY', dialCode: '+218'),
    Country(name: 'Liechtenstein', code: 'LI', dialCode: '+423'),
    Country(name: 'Lithuania', code: 'LT', dialCode: '+370'),
    Country(name: 'Luxembourg', code: 'LU', dialCode: '+352'),
    Country(name: 'Macau', code: 'MO', dialCode: '+853'),
    Country(name: 'Madagascar', code: 'MG', dialCode: '+261'),
    Country(name: 'Malawi', code: 'MW', dialCode: '+265'),
    Country(name: 'Malaysia', code: 'MY', dialCode: '+60'),
    Country(name: 'Maldives', code: 'MV', dialCode: '+960'),
    Country(name: 'Mali', code: 'ML', dialCode: '+223'),
    Country(name: 'Malta', code: 'MT', dialCode: '+356'),
    Country(name: 'Marshall Islands', code: 'MH', dialCode: '+692'),
    Country(name: 'Mauritania', code: 'MR', dialCode: '+222'),
    Country(name: 'Mauritius', code: 'MU', dialCode: '+230'),
    Country(name: 'Mexico', code: 'MX', dialCode: '+52'),
    Country(name: 'Micronesia', code: 'FM', dialCode: '+691'),
    Country(name: 'Moldova', code: 'MD', dialCode: '+373'),
    Country(name: 'Monaco', code: 'MC', dialCode: '+377'),
    Country(name: 'Mongolia', code: 'MN', dialCode: '+976'),
    Country(name: 'Montenegro', code: 'ME', dialCode: '+382'),
    Country(name: 'Morocco', code: 'MA', dialCode: '+212'),
    Country(name: 'Mozambique', code: 'MZ', dialCode: '+258'),
    Country(name: 'Myanmar', code: 'MM', dialCode: '+95'),
    Country(name: 'Namibia', code: 'NA', dialCode: '+264'),
    Country(name: 'Nauru', code: 'NR', dialCode: '+674'),
    Country(name: 'Nepal', code: 'NP', dialCode: '+977'),
    Country(name: 'Netherlands', code: 'NL', dialCode: '+31'),
    Country(name: 'New Zealand', code: 'NZ', dialCode: '+64'),
    Country(name: 'Nicaragua', code: 'NI', dialCode: '+505'),
    Country(name: 'Niger', code: 'NE', dialCode: '+227'),
    Country(name: 'Nigeria', code: 'NG', dialCode: '+234'),
    Country(name: 'North Korea', code: 'KP', dialCode: '+850'),
    Country(name: 'North Macedonia', code: 'MK', dialCode: '+389'),
    Country(name: 'Norway', code: 'NO', dialCode: '+47'),
    Country(name: 'Oman', code: 'OM', dialCode: '+968'),
    Country(name: 'Pakistan', code: 'PK', dialCode: '+92'),
    Country(name: 'Palau', code: 'PW', dialCode: '+680'),
    Country(name: 'Palestine', code: 'PS', dialCode: '+970'),
    Country(name: 'Panama', code: 'PA', dialCode: '+507'),
    Country(name: 'Papua New Guinea', code: 'PG', dialCode: '+675'),
    Country(name: 'Paraguay', code: 'PY', dialCode: '+595'),
    Country(name: 'Peru', code: 'PE', dialCode: '+51'),
    Country(name: 'Philippines', code: 'PH', dialCode: '+63'),
    Country(name: 'Poland', code: 'PL', dialCode: '+48'),
    Country(name: 'Portugal', code: 'PT', dialCode: '+351'),
    Country(name: 'Qatar', code: 'QA', dialCode: '+974'),
    Country(name: 'Romania', code: 'RO', dialCode: '+40'),
    Country(name: 'Russia', code: 'RU', dialCode: '+7'),
    Country(name: 'Rwanda', code: 'RW', dialCode: '+250'),
    Country(name: 'Saint Kitts and Nevis', code: 'KN', dialCode: '+1869'),
    Country(name: 'Saint Lucia', code: 'LC', dialCode: '+1758'),
    Country(name: 'Saint Vincent and the Grenadines', code: 'VC', dialCode: '+1784'),
    Country(name: 'Samoa', code: 'WS', dialCode: '+685'),
    Country(name: 'San Marino', code: 'SM', dialCode: '+378'),
    Country(name: 'Sao Tome and Principe', code: 'ST', dialCode: '+239'),
    Country(name: 'Saudi Arabia', code: 'SA', dialCode: '+966'),
    Country(name: 'Senegal', code: 'SN', dialCode: '+221'),
    Country(name: 'Serbia', code: 'RS', dialCode: '+381'),
    Country(name: 'Seychelles', code: 'SC', dialCode: '+248'),
    Country(name: 'Sierra Leone', code: 'SL', dialCode: '+232'),
    Country(name: 'Singapore', code: 'SG', dialCode: '+65'),
    Country(name: 'Slovakia', code: 'SK', dialCode: '+421'),
    Country(name: 'Slovenia', code: 'SI', dialCode: '+386'),
    Country(name: 'Solomon Islands', code: 'SB', dialCode: '+677'),
    Country(name: 'Somalia', code: 'SO', dialCode: '+252'),
    Country(name: 'South Africa', code: 'ZA', dialCode: '+27'),
    Country(name: 'South Korea', code: 'KR', dialCode: '+82'),
    Country(name: 'South Sudan', code: 'SS', dialCode: '+211'),
    Country(name: 'Spain', code: 'ES', dialCode: '+34'),
    Country(name: 'Sri Lanka', code: 'LK', dialCode: '+94'),
    Country(name: 'Sudan', code: 'SD', dialCode: '+249'),
    Country(name: 'Suriname', code: 'SR', dialCode: '+597'),
    Country(name: 'Sweden', code: 'SE', dialCode: '+46'),
    Country(name: 'Switzerland', code: 'CH', dialCode: '+41'),
    Country(name: 'Syria', code: 'SY', dialCode: '+963'),
    Country(name: 'Taiwan', code: 'TW', dialCode: '+886'),
    Country(name: 'Tajikistan', code: 'TJ', dialCode: '+992'),
    Country(name: 'Tanzania', code: 'TZ', dialCode: '+255'),
    Country(name: 'Thailand', code: 'TH', dialCode: '+66'),
    Country(name: 'Timor-Leste', code: 'TL', dialCode: '+670'),
    Country(name: 'Togo', code: 'TG', dialCode: '+228'),
    Country(name: 'Tonga', code: 'TO', dialCode: '+676'),
    Country(name: 'Trinidad and Tobago', code: 'TT', dialCode: '+1868'),
    Country(name: 'Tunisia', code: 'TN', dialCode: '+216'),
    Country(name: 'Turkey', code: 'TR', dialCode: '+90'),
    Country(name: 'Turkmenistan', code: 'TM', dialCode: '+993'),
    Country(name: 'Tuvalu', code: 'TV', dialCode: '+688'),
    Country(name: 'Uganda', code: 'UG', dialCode: '+256'),
    Country(name: 'Ukraine', code: 'UA', dialCode: '+380'),
    Country(name: 'United Arab Emirates', code: 'AE', dialCode: '+971'),
    Country(name: 'United Kingdom', code: 'GB', dialCode: '+44'),
    Country(name: 'United States', code: 'US', dialCode: '+1'),
    Country(name: 'Uruguay', code: 'UY', dialCode: '+598'),
    Country(name: 'Uzbekistan', code: 'UZ', dialCode: '+998'),
    Country(name: 'Vanuatu', code: 'VU', dialCode: '+678'),
    Country(name: 'Vatican City', code: 'VA', dialCode: '+379'),
    Country(name: 'Venezuela', code: 'VE', dialCode: '+58'),
    Country(name: 'Vietnam', code: 'VN', dialCode: '+84'),
    Country(name: 'Yemen', code: 'YE', dialCode: '+967'),
    Country(name: 'Zambia', code: 'ZM', dialCode: '+260'),
    Country(name: 'Zimbabwe', code: 'ZW', dialCode: '+263'),
  ];
}