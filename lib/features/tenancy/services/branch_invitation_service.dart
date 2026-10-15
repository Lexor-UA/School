import 'package:swimming_school_app/features/tenancy/models/branch.dart';

class BranchInvitationDetails {
  final String branchId;
  final String organizationId;
  final String branchName;
  final String flag;
  final String locationName;
  final String address;
  final String currencyCode;
  final String currencySymbol;
  final String primaryPoolName;
  final String registrationUrl;
  final String deepLink;
  final Map<String, String> welcomeMessages;

  const BranchInvitationDetails({
    required this.branchId,
    required this.organizationId,
    required this.branchName,
    required this.flag,
    required this.locationName,
    required this.address,
    required this.currencyCode,
    required this.currencySymbol,
    required this.primaryPoolName,
    required this.registrationUrl,
    required this.deepLink,
    required this.welcomeMessages,
  });

  String getWelcomeMessage(String locale) {
    return welcomeMessages[locale] ?? welcomeMessages['uk'] ?? '';
  }

  String getLocalizedBranchName(String locale) {
    if (branchId == 'vienna') {
      switch (locale.toLowerCase()) {
        case 'uk':
          return 'CitySwim Відень';
        case 'de':
          return 'CitySwim Wien';
        case 'ru':
          return 'CitySwim Вена';
        default:
          return 'CitySwim Vienna';
      }
    }
    if (branchId == 'kyiv') {
      switch (locale.toLowerCase()) {
        case 'en':
          return 'CitySwim Kyiv';
        case 'de':
          return 'CitySwim Kiew';
        case 'ru':
          return 'CitySwim Киев';
        default:
          return 'CitySwim Київ';
      }
    }
    return branchName;
  }

  String getLocalizedLocationName(String locale) {
    if (branchId == 'kyiv') {
      switch (locale.toLowerCase()) {
        case 'en':
          return 'Kyiv Aquatics Center';
        case 'de':
          return 'Schwimmzentrum Kiew';
        case 'ru':
          return 'Киевский Центр Плавания';
        default:
          return 'Київський Центр Плавання';
      }
    }
    return locationName;
  }

  String getLocalizedAddress(String locale) {
    if (branchId == 'vienna') {
      switch (locale.toLowerCase()) {
        case 'uk':
          return 'In der Au 1, 3400 Klosterneuburg, Австрія';
        case 'en':
          return 'In der Au 1, 3400 Klosterneuburg, Austria';
        case 'ru':
          return 'In der Au 1, 3400 Klosterneuburg, Австрия';
        default:
          return address;
      }
    }
    if (branchId == 'kyiv') {
      switch (locale.toLowerCase()) {
        case 'en':
          return '1 Sportyvna St, Kyiv, Ukraine';
        case 'de':
          return 'Sportywna-Str. 1, Kiew, Ukraine';
        case 'ru':
          return 'ул. Спортивная, 1, Киев, Украина';
        default:
          return address;
      }
    }
    return address;
  }

  String getLocalizedPrimaryPoolName(String locale) {
    if (primaryPoolName == 'Головний басейн 25м') {
      switch (locale.toLowerCase()) {
        case 'en':
          return 'Main Pool 25m';
        case 'de':
          return 'Hauptbecken 25m';
        case 'ru':
          return 'Главный бассейн 25м';
        default:
          return 'Головний басейн 25м';
      }
    }
    return primaryPoolName;
  }
}

class BranchInvitationService {
  static const String webBaseUrl = 'https://cityswim.app';
  static const String deepLinkScheme = 'cityswim';

  static final Map<String, Branch> _registeredBranches = {
    Branch.kyiv.id: Branch.kyiv,
    Branch.vienna.id: Branch.vienna,
  };

  /// Registers a dynamic branch so invitation URLs, QR codes, and metadata work for it
  static void registerBranch(Branch branch) {
    _registeredBranches[branch.id.trim().toLowerCase()] = branch;
  }

  /// Removes a deleted dynamic branch from the registry
  static void removeBranch(String branchId) {
    final key = branchId.trim().toLowerCase();
    if (key != 'kyiv' && key != 'vienna') {
      _registeredBranches.remove(key);
    }
  }

  /// Generates the public registration web URL for a branch (e.g. reception desk QR)
  static String buildRegistrationUrl(String branchId) {
    final normalized = normalizeBranchId(branchId);
    return '$webBaseUrl/register/$normalized';
  }

  /// Generates the in-app deep link URI
  static String buildDeepLink(String branchId) {
    final normalized = normalizeBranchId(branchId);
    return '$deepLinkScheme://register/$normalized';
  }

  /// Normalizes and validates branchId with fallback to kyiv
  static String normalizeBranchId(String? input) {
    if (input == null) return Branch.kyiv.id;
    final cleaned = input.trim().toLowerCase();
    if (cleaned.isEmpty) return Branch.kyiv.id;
    if (cleaned == 'vienna' || cleaned == 'wien') return 'vienna';
    if (cleaned == 'kyiv' || cleaned == 'kiev') return 'kyiv';
    if (_registeredBranches.containsKey(cleaned)) return cleaned;
    return Branch.kyiv.id;
  }

  /// Safely resolves branchId from any input (raw branchId, full URL, or deep link)
  static String resolveBranchFromUrlOrCode(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return Branch.kyiv.id;

    try {
      final uri = Uri.parse(trimmed);
      // Check query parameter ?branch=vienna
      final queryBranch = uri.queryParameters['branch'];
      if (queryBranch != null && queryBranch.isNotEmpty) {
        return normalizeBranchId(queryBranch);
      }

      // Check path segments /register/vienna
      final pathSegments = uri.pathSegments;
      final regIndex = pathSegments.indexOf('register');
      if (regIndex != -1 && regIndex + 1 < pathSegments.length) {
        return normalizeBranchId(pathSegments[regIndex + 1]);
      }
      if (pathSegments.isNotEmpty) {
        final last = pathSegments.last.toLowerCase();
        if (last == 'vienna' ||
            last == 'kyiv' ||
            last == 'wien' ||
            _registeredBranches.containsKey(last)) {
          return normalizeBranchId(last);
        }
      }
    } catch (_) {
      // Not a valid URI, treat as raw string
    }

    return normalizeBranchId(trimmed);
  }

  /// Returns detailed invitation and branding metadata for a branch
  static BranchInvitationDetails getInvitationDetails(String branchId) {
    final normalized = normalizeBranchId(branchId);

    if (normalized == 'vienna') {
      return BranchInvitationDetails(
        branchId: 'vienna',
        organizationId: 'cityswim',
        branchName: 'CitySwim Vienna',
        flag: '🇦🇹',
        locationName: 'HappyLand Klosterneuburg',
        address: 'In der Au 1, 3400 Klosterneuburg, Österreich',
        currencyCode: 'EUR',
        currencySymbol: '€',
        primaryPoolName: 'Sports Pool & Wellenbecken',
        registrationUrl: buildRegistrationUrl('vienna'),
        deepLink: buildDeepLink('vienna'),
        welcomeMessages: const {
          'uk': 'Ласкаво просимо до CitySwim Відень! Відскануйте для швидкої реєстрації дитини.',
          'de': 'Willkommen bei CitySwim Wien! Scannen Sie zur schnellen Kursregistrierung Ihres Kindes.',
          'en': 'Welcome to CitySwim Vienna! Scan for instant registration of your child.',
          'ru': 'Добро пожаловать в CitySwim Вена! Отсканируйте для быстрой регистрации ребенка.',
        },
      );
    }

    if (normalized != 'kyiv' && _registeredBranches.containsKey(normalized)) {
      final custom = _registeredBranches[normalized]!;
      return BranchInvitationDetails(
        branchId: custom.id,
        organizationId: custom.organizationId,
        branchName: 'CitySwim ${custom.name}',
        flag: custom.flagEmoji,
        locationName: '${custom.city} Aquatics Center',
        address: '${custom.city}, ${custom.country}',
        currencyCode: custom.currency,
        currencySymbol: custom.currencySymbol,
        primaryPoolName: 'Головний басейн 25м',
        registrationUrl: buildRegistrationUrl(custom.id),
        deepLink: buildDeepLink(custom.id),
        welcomeMessages: {
          'uk': 'Ласкаво просимо до CitySwim ${custom.name}! Відскануйте для швидкої реєстрації дитини.',
          'de': 'Willkommen bei CitySwim ${custom.name}! Scannen Sie zur Registrierung Ihres Kindes.',
          'en': 'Welcome to CitySwim ${custom.name}! Scan for instant registration of your child.',
          'ru': 'Добро пожаловать в CitySwim ${custom.name}! Отсканируйте для быстрой регистрации ребенка.',
        },
      );
    }

    return BranchInvitationDetails(
      branchId: 'kyiv',
      organizationId: 'cityswim',
      branchName: 'CitySwim Київ',
      flag: '🇺🇦',
      locationName: 'Київський Центр Плавання',
      address: 'вул. Спортивна, 1, Київ, Україна',
      currencyCode: 'UAH',
      currencySymbol: '₴',
      primaryPoolName: 'Головний басейн 25м',
      registrationUrl: buildRegistrationUrl('kyiv'),
      deepLink: buildDeepLink('kyiv'),
      welcomeMessages: const {
        'uk': 'Ласкаво просимо до CitySwim Київ! Відскануйте для швидкої реєстрації дитини.',
        'de': 'Willkommen bei CitySwim Kiew! Scannen Sie zur Registrierung Ihres Kindes.',
        'en': 'Welcome to CitySwim Kyiv! Scan for instant registration of your child.',
        'ru': 'Добро пожаловать в CitySwim Киев! Отсканируйте для быстрой регистрации ребенка.',
      },
    );
  }
}
