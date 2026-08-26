import 'dart:io';

void main() {
  final poolMapFile = File(r'c:\Users\Nelia\Desktop\School\lib\features\parent\presentation\pool_map_screen.dart');
  var pContent = poolMapFile.readAsStringSync();
  pContent = pContent.replaceAll('''                  IconButton(
                    icon: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
              ),
            ),
          ),''', '''                  IconButton(
                    icon: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'parent.3d_pool_map'.tr(),
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ).animate().fadeIn().slideY(begin: -0.2),
                        const SizedBox(height: 4),
                        Text(
                          'parent.swipe_to_rotate'.tr(),
                          style: const TextStyle(color: Colors.cyanAccent, fontSize: 13),
                        ).animate().fadeIn(delay: 200.ms),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),''');
  poolMapFile.writeAsStringSync(pContent);

  final trophyFile = File(r'c:\Users\Nelia\Desktop\School\lib\features\parent\presentation\trophy_room_screen.dart');
  var tContent = trophyFile.readAsStringSync();
  tContent = tContent.replaceAll('''                  padding: const EdgeInsets.all(24),
                  icon: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 32),
                  onPressed: () => Navigator.pop(context),
                
                // 3D Cabinet View
                Expanded''', '''                  padding: const EdgeInsets.all(24),
                  icon: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 32),
                  onPressed: () => Navigator.pop(context),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'parent.trophy_showcase'.tr(),
                        style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                      ).animate().fadeIn().slideY(begin: -0.2),
                      const SizedBox(height: 8),
                      Text(
                        'parent.click_trophy_for_details'.tr(),
                        style: const TextStyle(color: Colors.white54, fontSize: 16),
                      ).animate().fadeIn(delay: 200.ms),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // 3D Cabinet View
                Expanded''');
  trophyFile.writeAsStringSync(tContent);

  final anatomyFile = File(r'c:\Users\Nelia\Desktop\School\lib\features\parent\presentation\anatomy_progress_screen.dart');
  var aContent = anatomyFile.readAsStringSync();
  
  aContent = aContent.replaceAll("child: const Row(", "child: Row(");
  aContent = aContent.replaceAll("const Text(\n                          'parent.anatomy_progress_upper'.tr(),", "Text(\n                          'parent.anatomy_progress_upper'.tr(),");
  aContent = aContent.replaceAll("const Text(\n                          'parent.biometric_analysis'.tr(),", "Text(\n                          'parent.biometric_analysis'.tr(),");
  aContent = aContent.replaceAll("const Row(\n                children: [\n                  Icon(LucideIcons.target", "Row(\n                children: [\n                  Icon(LucideIcons.target");
  
  anatomyFile.writeAsStringSync(aContent);
  
  print('Done applying script!');
}
