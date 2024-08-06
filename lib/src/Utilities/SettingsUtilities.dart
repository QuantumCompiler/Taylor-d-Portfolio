import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../Utilities/GlobalUtils.dart';

Future<void> pickAndCopy(String newName) async {
  String? sourceDirectoryPath = await FilePicker.platform.getDirectoryPath();
  if (sourceDirectoryPath != null) {
    Directory destinationDirectory = await GetLaTeXDir();
    Directory sourceDirectory = Directory(sourceDirectoryPath);
    Directory newDestinationDirectory = Directory('${destinationDirectory.path}/$newName');
    if (newDestinationDirectory.existsSync()) {
      await newDestinationDirectory.delete(recursive: true);
    }
    await newDestinationDirectory.create();
    await CopyDir(sourceDirectory, newDestinationDirectory, false);
  }
}
