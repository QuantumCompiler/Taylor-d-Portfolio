import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive_io.dart';
import 'dart:convert';
import 'dart:io';

Future<String> fetchMessage() async {
  final response = await http.get(Uri.parse('http://18.222.120.48:3000'));

  if (response.statusCode == 200) {
    var decodedResponse = jsonDecode(response.body);
    return decodedResponse['message'];
  } else {
    throw Exception('Failed to load message');
  }
}

Future<void> uploadDirectory() async {
  String? directoryPath = await FilePicker.platform.getDirectoryPath();
  if (directoryPath != null) {
    Directory directory = Directory(directoryPath);

    // Create a ZIP file from the directory in the cache directory
    final cacheDir = await getApplicationCacheDirectory();
    final zipFilePath = '${cacheDir.path}/Resume.zip';
    final zipFile = File(zipFilePath);

    var encoder = ZipFileEncoder();
    encoder.create(zipFile.path);
    directory.listSync(recursive: true).forEach((file) {
      if (file is File) {
        encoder.addFile(file);
      }
    });
    encoder.close();

    // Upload the ZIP file
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('http://18.222.120.48:4000/compile'), // Replace with your actual server URL
    );
    request.files.add(await http.MultipartFile.fromPath('file', zipFile.path));

    var response = await request.send();

    if (response.statusCode == 200) {
      final bytes = await response.stream.toBytes();
      final compiledFilePath = '${cacheDir.path}/compiled_latex.zip';
      final compiledFile = File(compiledFilePath);
      await compiledFile.writeAsBytes(bytes);

      print('File downloaded to $compiledFilePath');
    } else {
      print('Failed to upload directory');
    }

    // Clean up the ZIP file
    zipFile.deleteSync();
  }
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<String> message;

  @override
  void initState() {
    super.initState();
    message = fetchMessage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hello, Taylor'),
      ),
      body: Center(
        child: FutureBuilder<String>(
          future: message,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              return Text(snapshot.data ?? 'No message');
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await uploadDirectory();
        },
        child: Icon(Icons.upload),
      ),
    );
  }
}
