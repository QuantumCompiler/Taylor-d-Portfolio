import 'package:path_provider/path_provider.dart';
import 'dart:io';

Future<void> DeleteAllProfiles() async {
  final appDir = await getApplicationDocumentsDirectory();
  final profileDir = Directory('${appDir.path}/Profiles');
  final profiles = profileDir.listSync().where((item) => item is Directory).cast<Directory>();
  for (var profs in profiles) {
    profs.deleteSync(recursive: true);
  }
}
