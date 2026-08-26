import 'dart:io';

void main() {
  final basePath = r'c:\Users\Nelia\Desktop\School\lib\features\parent\presentation';
  final dir = Directory(basePath);
  
  for (final file in dir.listSync()) {
    if (file is File && file.path.endsWith('.dart')) {
      var content = file.readAsStringSync();
      content = content.replaceAll("const Text('parent.", "Text('parent.");
      content = content.replaceAll("const Center(child: Text('parent.", "Center(child: Text('parent.");
      content = content.replaceAll("const Center(child: Padding(", "Center(child: Padding(");
      content = content.replaceAll("title: const Text('parent.", "title: Text('parent.");
      content = content.replaceAll("child: const Text('parent.", "child: Text('parent.");
      file.writeAsStringSync(content);
    }
  }

  final poolMapFile = File(r'c:\Users\Nelia\Desktop\School\lib\features\parent\presentation\pool_map_screen.dart');
  var pContent = poolMapFile.readAsStringSync();
  if (!pContent.contains('class PoolMapScreen extends StatefulWidget')) {
    final toAdd = '''class PoolMapScreen extends StatefulWidget {
  final int? targetLane;
  final String? groupName;
  final String? coachName;
  final String? timeSlot;

  const PoolMapScreen({
    super.key,
    this.targetLane = 2,
    this.groupName = 'parent.juniors_pro',
    this.coachName = 'parent.oleksandr_v',
    this.timeSlot = '16:00 - 17:00',
  });

  @override
  State<PoolMapScreen> createState() => _PoolMapScreenState();
}

''';
    pContent = pContent.replaceFirst('class _PoolMapScreenState', toAdd + 'class _PoolMapScreenState');
  }
  
  // Try to replace groupName and coachName with .tr() calls dynamically, since they no longer have .tr() in constructor
  pContent = pContent.replaceAll('widget.groupName ??', 'widget.groupName?.tr() ??');
  pContent = pContent.replaceAll('widget.coachName ??', 'widget.coachName?.tr() ??');
  // Also if they are force unwrapped
  pContent = pContent.replaceAll('widget.groupName!', 'widget.groupName!.tr()');
  pContent = pContent.replaceAll('widget.coachName!', 'widget.coachName!.tr()');

  poolMapFile.writeAsStringSync(pContent);
  print('Fix applied successfully.');
}
