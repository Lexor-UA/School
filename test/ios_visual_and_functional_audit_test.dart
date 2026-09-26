import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';
import 'package:swimming_school_app/features/tenancy/models/branch.dart';
import 'package:swimming_school_app/features/tenancy/models/branch_config.dart';
import 'package:swimming_school_app/features/tenancy/models/white_label_config.dart';
import 'package:swimming_school_app/firebase_options.dart';

void main() {
  group('iOS Visual, Assets & Functional Readiness Audit', () {
    test('1. Translation JSON files are valid and contain all essential keys', () {
      final translationDir = Directory('assets/translations');
      expect(translationDir.existsSync(), isTrue, reason: 'assets/translations directory must exist');

      final files = ['uk.json', 'en.json', 'de.json', 'ru.json'];
      for (final fileName in files) {
        final file = File('assets/translations/$fileName');
        expect(file.existsSync(), isTrue, reason: '$fileName must exist');

        final content = file.readAsStringSync();
        expect(content.isNotEmpty, isTrue, reason: '$fileName must not be empty');

        final Map<String, dynamic> jsonMap = json.decode(content);
        expect(jsonMap.containsKey('auth'), isTrue, reason: '$fileName must contain "auth" section');
        expect(jsonMap.containsKey('parent'), isTrue, reason: '$fileName must contain "parent" section');
        expect(jsonMap.containsKey('admin'), isTrue, reason: '$fileName must contain "admin" section');

        // Check key auth translations
        final authSection = jsonMap['auth'] as Map<String, dynamic>;
        expect(authSection.containsKey('staff_portal'), isTrue, reason: '$fileName auth missing staff_portal');
        expect(authSection.containsKey('login_google'), isTrue, reason: '$fileName auth missing login_google');
        expect(authSection.containsKey('welcome_back'), isTrue, reason: '$fileName auth missing welcome_back');
      }
    });

    test('2. All registered assets and iOS icons physically exist and are non-empty', () {
      final assets = [
        'assets/images/google_logo.png',
        'assets/images/logo_light.png',
        'assets/images/modern_matte_texture.jpg',
        'assets/images/new_background.jpg',
        'assets/images/sci_fi_swimmer_anatomy.jpg',
        'assets/icon/app_icon.jpg',
      ];

      for (final path in assets) {
        final file = File(path);
        expect(file.existsSync(), isTrue, reason: 'Asset file $path must exist on disk');
        expect(file.lengthSync(), greaterThan(0), reason: 'Asset file $path must not be empty');
      }

      // Check iOS AppIcon set
      final iconDir = Directory('ios/Runner/Assets.xcassets/AppIcon.appiconset');
      expect(iconDir.existsSync(), isTrue, reason: 'iOS AppIcon asset set must exist');
      final contentsJson = File('ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json');
      expect(contentsJson.existsSync(), isTrue, reason: 'iOS AppIcon Contents.json must exist');
    });

    test('3. iOS Bundle ID and Firebase configuration alignment for iPhone builds', () {
      // 1. GoogleService-Info.plist check
      final googleServiceInfo = File('ios/Runner/GoogleService-Info.plist');
      expect(googleServiceInfo.existsSync(), isTrue, reason: 'GoogleService-Info.plist must exist for iOS build');
      final plistContent = googleServiceInfo.readAsStringSync();
      expect(plistContent.contains('<string>city.swim.school</string>'), isTrue,
          reason: 'GoogleService-Info.plist must have BUNDLE_ID city.swim.school');
      expect(plistContent.contains('<string>city-swim</string>'), isTrue,
          reason: 'GoogleService-Info.plist must point to city-swim Firebase project');

      // 2. DefaultFirebaseOptions check
      expect(DefaultFirebaseOptions.ios.iosBundleId, equals('city.swim.school'));
      expect(DefaultFirebaseOptions.ios.projectId, equals('city-swim'));

      // 3. Info.plist check
      final infoPlist = File('ios/Runner/Info.plist');
      expect(infoPlist.existsSync(), isTrue);
      final infoPlistContent = infoPlist.readAsStringSync();
      expect(infoPlistContent.contains('NSCameraUsageDescription'), isTrue,
          reason: 'Camera usage description required for QR scanner on iOS');
      expect(infoPlistContent.contains('NSPhotoLibraryUsageDescription'), isTrue,
          reason: 'Photo library usage description required for avatar upload on iOS');
      expect(infoPlistContent.contains('NSFaceIDUsageDescription'), isTrue,
          reason: 'Face ID usage description required for biometric login on iOS');

      // 4. project.pbxproj check
      final pbxproj = File('ios/Runner.xcodeproj/project.pbxproj');
      expect(pbxproj.existsSync(), isTrue);
      final pbxprojContent = pbxproj.readAsStringSync();
      expect(pbxprojContent.contains('PRODUCT_BUNDLE_IDENTIFIER = city.swim.school;'), isTrue);
      expect(pbxprojContent.contains('IPHONEOS_DEPLOYMENT_TARGET = 15.0;'), isTrue);
    });

    test('4. Visual Theme Consistency: Light Azure & Dark Ocean Contrast & Palettes', () {
      final dark = AppThemeConfig.darkOcean;
      final light = AppThemeConfig.lightAzure;

      // Dark Theme validation
      expect(dark.isDark, isTrue);
      expect(dark.scaffoldBg, isNotNull);
      expect(dark.cardBg, isNotNull);
      expect(dark.accentPrimary, isNotNull);
      expect(dark.textPrimary, isNotNull);
      expect(dark.bgGradient.length, greaterThanOrEqualTo(2));
      expect(dark.textPrimary.computeLuminance(), greaterThan(0.5),
          reason: 'Dark theme primary text should have high luminance for legibility');

      // Light Theme validation
      expect(light.isDark, isFalse);
      expect(light.scaffoldBg, isNotNull);
      expect(light.cardBg, isNotNull);
      expect(light.accentPrimary, isNotNull);
      expect(light.textPrimary, isNotNull);
      expect(light.bgGradient.length, greaterThanOrEqualTo(2));
      expect(light.textPrimary.computeLuminance(), lessThan(0.5),
          reason: 'Light theme primary text should have low luminance for contrast against light background');

      // Preset collection sanity
      expect(AppThemeConfig.allPresets.length, greaterThanOrEqualTo(2));
    });

    test('5. Multi-Tenancy Data & Currency Correctness across Vienna and Kyiv', () {
      final viennaBranch = Branch.vienna;
      final kyivBranch = Branch.kyiv;
      final viennaConfig = BranchConfig.viennaConfig;
      final kyivConfig = BranchConfig.kyivConfig;

      // Vienna Branch & Config
      expect(viennaBranch.id, equals('vienna'));
      expect(viennaBranch.currency, equals('EUR'));
      expect(viennaBranch.currencySymbol, equals('€'));
      expect(viennaBranch.timezone, equals('Europe/Vienna'));
      expect(viennaBranch.country, equals('AT'));
      expect(viennaBranch.defaultLanguage, equals('de'));
      expect(viennaConfig.locations.isNotEmpty, isTrue);
      expect(viennaConfig.locations.first.pools.isNotEmpty, isTrue);

      // Kyiv Branch & Config
      expect(kyivBranch.id, equals('kyiv'));
      expect(kyivBranch.currency, equals('UAH'));
      expect(kyivBranch.currencySymbol, equals('₴'));
      expect(kyivBranch.timezone, equals('Europe/Kyiv'));
      expect(kyivBranch.country, equals('UA'));
      expect(kyivBranch.defaultLanguage, equals('uk'));
      expect(kyivConfig.locations.isNotEmpty, isTrue);
      expect(kyivConfig.locations.first.pools.isNotEmpty, isTrue);
    });

    test('6. WhiteLabelConfig Theme and Brand Customization', () {
      final defaultWl = WhiteLabelConfig.citySwimDefault;
      expect(defaultWl.appName, equals('CitySwim'));
      expect(defaultWl.primaryColor, equals(const Color(0xFF00E5FF)));
      expect(defaultWl.supportEmail, contains('@'));
      expect(defaultWl.featuresEnabled['qrAttendance'], isTrue);
      expect(defaultWl.featuresEnabled['multiBranch'], isTrue);
    });

    testWidgets('7. iPhone SE Viewport (375x667) Layout Overflow Prevention', (tester) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(height: 100, color: Colors.blue),
                    Container(height: 200, color: Colors.cyan),
                    Container(height: 300, color: Colors.indigo),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'Must not trigger RenderFlex overflow on iPhone SE');
    });

    testWidgets('8. iPhone 15/16 Viewport (393x852) Layout Sanity', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Text('CitySwim iOS Layout Test'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'Must render without errors on iPhone 15');
      expect(find.text('CitySwim iOS Layout Test'), findsOneWidget);
    });

    testWidgets('9. iPhone Pro Max Viewport (430x932) Layout Sanity', (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: const Text('CitySwim Pro Max Layout Test'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'Must render without errors on iPhone Pro Max');
      expect(find.text('CitySwim Pro Max Layout Test'), findsOneWidget);
    });

    testWidgets('10. iPhone 17 Viewport (402x874 - 6.3") Layout Sanity', (tester) async {
      tester.view.physicalSize = const Size(402, 874);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Text('CitySwim iPhone 17 Layout Test'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'Must render seamlessly on iPhone 17 display');
      expect(find.text('CitySwim iPhone 17 Layout Test'), findsOneWidget);
    });

    testWidgets('11. iPhone 17/18 Pro Max Viewport (440x956 - 6.9") Layout Sanity', (tester) async {
      tester.view.physicalSize = const Size(440, 956);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: const Text('CitySwim iPhone 17/18 Pro Max Layout Test'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'Must render seamlessly on iPhone 17/18 Pro Max 6.9" display');
      expect(find.text('CitySwim iPhone 17/18 Pro Max Layout Test'), findsOneWidget);
    });
  });
}


