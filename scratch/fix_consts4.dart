import 'dart:io';

void main() {
  final basePath = r'c:\Users\Nelia\Desktop\School\lib\features\parent\presentation';
  final dir = Directory(basePath);
  
  for (final file in dir.listSync()) {
    if (file is File && file.path.endsWith('.dart')) {
      var content = file.readAsStringSync();
      
      content = content.replaceAll(RegExp(r'const\s+Text\('), 'Text(');
      content = content.replaceAll(RegExp(r'const\s+Row\('), 'Row(');
      content = content.replaceAll(RegExp(r'const\s+Expanded\('), 'Expanded(');
      content = content.replaceAll(RegExp(r'const\s+Center\('), 'Center(');
      content = content.replaceAll(RegExp(r'const\s+Padding\('), 'Padding(');
      
      if (file.path.endsWith('pool_map_screen.dart')) {
        content = content.replaceAll("this.groupName = 'parent.juniors_pro'.tr(),", "this.groupName = 'parent.juniors_pro',");
        content = content.replaceAll("this.coachName = 'parent.oleksandr_v'.tr(),", "this.coachName = 'parent.oleksandr_v',");
        content = content.replaceAll("Text(widget.groupName!)", "Text(widget.groupName!.tr())");
        content = content.replaceAll("Text(widget.coachName!)", "Text(widget.coachName!.tr())");
      }
      
      file.writeAsStringSync(content);
    }
  }

  print('Brute force const removal applied!');
}
