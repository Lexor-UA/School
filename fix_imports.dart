import 'dart:io';

void main() {
  final dir = Directory('lib');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    String content = file.readAsStringSync();
    
    content = content.replaceAll(RegExp(r"import '(\.\./)+controllers/auth_controller.dart';"), "import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';");
    content = content.replaceAll(RegExp(r"import '(\.\./)+controllers/theme_controller.dart';"), "import 'package:swimming_school_app/core/theme/theme_controller.dart';");
    content = content.replaceAll("import 'controllers/theme_controller.dart';", "import 'package:swimming_school_app/core/theme/theme_controller.dart';");
    content = content.replaceAll(RegExp(r"import '(\.\./)+controllers/subscription_controller.dart';"), "import 'package:swimming_school_app/features/subscription/controllers/subscription_controller.dart';");
    
    content = content.replaceAll(RegExp(r"import '(\.\./)+models/app_user.dart';"), "import 'package:swimming_school_app/features/auth/models/app_user.dart';");
    content = content.replaceAll(RegExp(r"import '(\.\./)+models/subscription.dart';"), "import 'package:swimming_school_app/features/subscription/models/subscription.dart';");
    
    content = content.replaceAllMapped(RegExp(r"import '(\.\./)+widgets/([^']+).dart';"), (m) => "import 'package:swimming_school_app/shared/widgets/${m.group(2)}.dart';");
    
    content = content.replaceAll(RegExp(r"import '(\.\./)+utils/page_transitions.dart';"), "import 'package:swimming_school_app/shared/utils/page_transitions.dart';");
    
    content = content.replaceAll(RegExp(r"import '(\.\./)+core/theme.dart';"), "import 'package:swimming_school_app/core/theme/theme.dart';");
    content = content.replaceAll("import 'core/theme.dart';", "import 'package:swimming_school_app/core/theme/theme.dart';");
    content = content.replaceAll("import 'package:swimming_school_app/core/theme.dart';", "import 'package:swimming_school_app/core/theme/theme.dart';");

    content = content.replaceAll("import 'parent_home_tab.dart';", "import 'package:swimming_school_app/features/parent/presentation/parent_home_tab.dart';");
    content = content.replaceAll("import 'parent_schedule_tab.dart';", "import 'package:swimming_school_app/features/parent/presentation/parent_schedule_tab.dart';");
    content = content.replaceAll("import 'parent_profile_tab.dart';", "import 'package:swimming_school_app/features/parent/presentation/parent_profile_tab.dart';");
    content = content.replaceAll("import 'anatomy_progress_screen.dart';", "import 'package:swimming_school_app/features/parent/presentation/anatomy_progress_screen.dart';");
    content = content.replaceAll("import 'trophy_room_screen.dart';", "import 'package:swimming_school_app/features/parent/presentation/trophy_room_screen.dart';");
    content = content.replaceAll("import 'pool_map_screen.dart';", "import 'package:swimming_school_app/features/parent/presentation/pool_map_screen.dart';");
    content = content.replaceAll("import 'qr_scanner_screen.dart';", "import 'package:swimming_school_app/features/coach/presentation/qr_scanner_screen.dart';");
    content = content.replaceAll("import 'parent_dashboard.dart';", "import 'package:swimming_school_app/features/parent/presentation/parent_dashboard.dart';");
    
    file.writeAsStringSync(content);
  }
}
