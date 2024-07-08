import '../Globals/Globals.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;

Future<void> pickAndCopy(String newName) async {
  String? sourceDirectoryPath = await FilePicker.platform.getDirectoryPath();
  if (sourceDirectoryPath != null) {
    Directory destinationDirectory = await GetLaTeXDir();
    Directory sourceDirectory = Directory(sourceDirectoryPath);
    Directory newDestinationDirectory = Directory('${destinationDirectory.path}/$newName');
    if (newDestinationDirectory.existsSync()) {
      newDestinationDirectory.delete(recursive: true);
    }
    await newDestinationDirectory.create(recursive: true);
    List<FileSystemEntity> entities = sourceDirectory.listSync();
    for (FileSystemEntity entity in entities) {
      String newPath = path.join(newDestinationDirectory.path, path.basename(entity.path));
      if (entity is File) {
        File newFile = File(newPath);
        await newFile.writeAsBytes(await entity.readAsBytes());
      } else if (entity is Directory) {
        Directory newDirectory = Directory(newPath);
        await newDirectory.create();
        await copyDirectory(entity, newDirectory);
      }
    }
  }
}

Future<void> copyDirectory(Directory source, Directory destination) async {
  await for (var entity in source.list(recursive: false)) {
    String newPath = path.join(destination.path, path.basename(entity.path));
    if (entity is Directory) {
      Directory newDirectory = Directory(newPath);
      await newDirectory.create();
      await copyDirectory(entity, newDirectory);
    } else if (entity is File) {
      await entity.copy(newPath);
    }
  }
}
