import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdf/pdf.dart';

class TextExtractionService {
  Future<String> extractTextFromUrl(String url, String fileName) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) return '';
    return extractText(response.bodyBytes, fileName);
  }

  Future<String> extractTextFromBytes(Uint8List bytes, String fileName) async {
    return extractText(bytes, fileName);
  }

  String extractText(Uint8List bytes, String fileName) {
    final lower = fileName.toLowerCase();

    if (lower.endsWith('.txt')) {
      return utf8.decode(bytes);
    }

    if (lower.endsWith('.pdf')) {
      try {
        final document = PdfDocument(inputBytes: bytes.toList());
        final text = PdfTextExtractor(document).extractText();
        document.dispose();
        return text;
      } catch (e) {
        return '';
      }
    }

    return '';
  }
}
