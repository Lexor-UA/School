import 'dart:io';
import 'dart:convert';

void main() {
  final anatomyFile = File(r'c:\Users\Nelia\Desktop\School\lib\features\parent\presentation\anatomy_progress_screen.dart');
  var aContent = anatomyFile.readAsStringSync();
  
  aContent = aContent.replaceAll(
    "String _selectedStyle = 'Кроль';",
    "String _selectedStyle = 'parent.style_crawl';",
  );
  
  aContent = aContent.replaceAll(
    "'Кроль': ['плечі', 'руки', 'кор'],",
    "'parent.style_crawl': ['shoulders', 'arms', 'core'],",
  );
  
  aContent = aContent.replaceAll(
    "'Брас': ['ноги', 'кор', 'руки'],",
    "'parent.style_breaststroke': ['legs', 'core', 'arms'],",
  );
  
  aContent = aContent.replaceAll(
    "'Батерфляй': ['плечі', 'кор', 'руки', 'ноги'],",
    "'parent.style_butterfly': ['shoulders', 'core', 'arms', 'legs'],",
  );
  
  aContent = aContent.replaceAll(
    "'На спині': ['плечі', 'ноги'],",
    "'parent.style_backstroke': ['shoulders', 'legs'],",
  );
  
  aContent = aContent.replaceAll(
    "'плечі': 0.85,",
    "'shoulders': 0.85,",
  );
  
  aContent = aContent.replaceAll(
    "'кор': 0.70,",
    "'core': 0.70,",
  );
  
  aContent = aContent.replaceAll(
    "'руки': 0.60,",
    "'arms': 0.60,",
  );
  
  aContent = aContent.replaceAll(
    "'ноги': 0.90,",
    "'legs': 0.90,",
  );
  
  aContent = aContent.replaceAll(
    "style.toUpperCase(),",
    "style.tr().toUpperCase(),",
  );
  
  aContent = aContent.replaceAll(
    "Text(muscle.toUpperCase(),",
    "Text('parent.\$muscle'.tr().toUpperCase(),",
  );
  
  anatomyFile.writeAsStringSync(aContent);
  
  final poolMapFile = File(r'c:\Users\Nelia\Desktop\School\lib\features\parent\presentation\pool_map_screen.dart');
  var pContent = poolMapFile.readAsStringSync();
  
  pContent = pContent.replaceAll(
    "widget.groupName ?? '', ",
    "(widget.groupName?.tr()) ?? '', ",
  );
  
  pContent = pContent.replaceAll(
    "widget.coachName ?? '', ",
    "(widget.coachName?.tr()) ?? '', ",
  );
  
  poolMapFile.writeAsStringSync(pContent);

  final translations = {
    "uk.json": {
      "parent.style_crawl": "Кроль",
      "parent.style_breaststroke": "Брас",
      "parent.style_butterfly": "Батерфляй",
      "parent.style_backstroke": "На спині",
      "parent.shoulders": "Плечі",
      "parent.arms": "Руки",
      "parent.core": "Кор",
      "parent.legs": "Ноги",
      "parent.chest": "Груди",
      "parent.back": "Спина"
    },
    "en.json": {
      "parent.style_crawl": "Freestyle",
      "parent.style_breaststroke": "Breaststroke",
      "parent.style_butterfly": "Butterfly",
      "parent.style_backstroke": "Backstroke",
      "parent.shoulders": "Shoulders",
      "parent.arms": "Arms",
      "parent.core": "Core",
      "parent.legs": "Legs",
      "parent.chest": "Chest",
      "parent.back": "Back"
    },
    "de.json": {
      "parent.style_crawl": "Kraulschwimmen",
      "parent.style_breaststroke": "Brustschwimmen",
      "parent.style_butterfly": "Schmetterling",
      "parent.style_backstroke": "Rückenschwimmen",
      "parent.shoulders": "Schultern",
      "parent.arms": "Arme",
      "parent.core": "Kern",
      "parent.legs": "Beine",
      "parent.chest": "Brust",
      "parent.back": "Rücken"
    },
    "ru.json": {
      "parent.style_crawl": "Кроль",
      "parent.style_breaststroke": "Брасс",
      "parent.style_butterfly": "Баттерфляй",
      "parent.style_backstroke": "На спине",
      "parent.shoulders": "Плечи",
      "parent.arms": "Руки",
      "parent.core": "Кор",
      "parent.legs": "Ноги",
      "parent.chest": "Грудь",
      "parent.back": "Спина"
    }
  };

  final basePath = r'c:\Users\Nelia\Desktop\School\assets\translations';
  final dir = Directory(basePath);
  
  for (final file in dir.listSync()) {
    if (file is File && file.path.endsWith('.json')) {
      final fileName = file.path.split(Platform.pathSeparator).last;
      if (translations.containsKey(fileName)) {
        final content = file.readAsStringSync();
        final Map<String, dynamic> jsonMap = jsonDecode(content);
        jsonMap.addAll(translations[fileName]!);
        const JsonEncoder encoder = JsonEncoder.withIndent('  ');
        file.writeAsStringSync(encoder.convert(jsonMap));
      }
    }
  }

  print('Final fixes applied!');
}
