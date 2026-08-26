import 'dart:io';

void main() {
  final basePath = r'c:\Users\Nelia\Desktop\School\lib\features\parent\presentation';
  final dir = Directory(basePath);
  
  for (final file in dir.listSync()) {
    if (file is File && file.path.endsWith('.dart')) {
      var content = file.readAsStringSync();
      
      content = content.replaceAll("title: const Text('parent.schedule_history'", "title: Text('parent.schedule_history'");
      content = content.replaceAll("const Center(child: Text('parent.no_classes_available'", "Center(child: Text('parent.no_classes_available'");
      content = content.replaceAll("child: const Text('parent.no_bookings_yet'", "child: Text('parent.no_bookings_yet'");
      content = content.replaceAll("const Expanded(\n                      child: Text('parent.juniors_swimming'", "Expanded(\n                      child: Text('parent.juniors_swimming'");

      content = content.replaceAll("this.groupName = 'parent.juniors_pro'.tr(),", "this.groupName = 'parent.juniors_pro',");
      content = content.replaceAll("this.coachName = 'parent.oleksandr_v'.tr(),", "this.coachName = 'parent.oleksandr_v',");
      content = content.replaceAll("const Text(\n                          'parent.3d_pool_map'.tr(),", "Text(\n                          'parent.3d_pool_map'.tr(),");
      content = content.replaceAll("const Text(\n                          'parent.swipe_to_rotate'.tr(),", "Text(\n                          'parent.swipe_to_rotate'.tr(),");
      content = content.replaceAll("Text(widget.groupName!)", "Text(widget.groupName!.tr())");
      content = content.replaceAll("Text(widget.coachName!)", "Text(widget.coachName!.tr())");

      content = content.replaceAll("const Text(\n                        'parent.trophy_showcase'", "Text(\n                        'parent.trophy_showcase'");
      content = content.replaceAll("const Text(\n                        'parent.click_trophy_for_details'", "Text(\n                        'parent.click_trophy_for_details'");
      content = content.replaceAll("child: const Text('parent.close'", "child: Text('parent.close'");

      content = content.replaceAll("child: const Row(\n                          children: [\n                            Icon", "child: Row(\n                          children: [\n                            const Icon");
      content = content.replaceAll("const Text(\n                          'parent.anatomy_progress_upper'", "Text(\n                          'parent.anatomy_progress_upper'");
      content = content.replaceAll("const Text(\n                          'parent.biometric_analysis'", "Text(\n                          'parent.biometric_analysis'");
      content = content.replaceAll("const Row(\n                children: [\n                  Icon(LucideIcons.target", "Row(\n                children: [\n                  const Icon(LucideIcons.target");

      file.writeAsStringSync(content);
    }
  }

  print('Done precise fix!');
}
