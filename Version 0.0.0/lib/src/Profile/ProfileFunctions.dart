import 'dart:convert';

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

Future<void> ReadProfileData(String profile) async {
  final appDir = await getApplicationDocumentsDirectory();
  final profileDir = Directory('${appDir.path}/Profiles/$profile');
  final profileJSON = File('${profileDir.path}/data.json');
  if (await profileJSON.existsSync()) {
    final profileData = await profileJSON.readAsString();
    return jsonDecode(profileData);
  } else {
    throw Exception('Profile data not found');
  }
}
