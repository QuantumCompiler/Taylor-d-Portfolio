import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: PdfTextExtractorPage(),
    );
  }
}

class PdfTextExtractorPage extends StatefulWidget {
  const PdfTextExtractorPage({super.key});

  @override
  _PdfTextExtractorPageState createState() => _PdfTextExtractorPageState();
}

class _PdfTextExtractorPageState extends State<PdfTextExtractorPage> {
  String extractedText = '';

  Future<void> pickAndExtractText() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      String filePath = result.files.single.path!;
      File file = File(filePath);
      Uint8List bytes = await file.readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      String content = PdfTextExtractor(document).extractText();
      document.dispose();

      // Format the extracted text
      content = formatExtractedText(content);

      setState(() {
        extractedText = content;
      });
    }
  }

  String formatExtractedText(String text) {
    // Trim leading and trailing whitespace
    text = text.trim();

    // Replace multiple newlines with a single newline
    text = text.replaceAll(RegExp(r'\n\s*\n'), '\n\n');

    // Add spaces where they are missing between words
    text = text.replaceAllMapped(
      RegExp(r'(?<=[a-zA-Z])(?=[A-Z])'),
      (Match match) => ' ',
    );

    // Add paragraph spacing
    text = text.replaceAll('\n\n', '\n\n');

    return text;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PDF Text Extractor'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextButton(
              onPressed: pickAndExtractText,
              child: Text('Pick PDF and Extract Text'),
            ),
            SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  extractedText,
                  style: TextStyle(fontSize: 16, height: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
