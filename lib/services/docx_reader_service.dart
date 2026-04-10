import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

/// Service utilitaire pour extraire du texte brut depuis un fichier DOCX.
class DocxReaderService {
  static const String _documentXmlPath = 'word/document.xml';

  /// Extrait le texte lisible depuis les [docxBytes].
  ///
  /// Le fichier DOCX est un zip contenant du XML WordprocessingML.
  /// Cette methode lit `word/document.xml` puis reconstruit le texte
  /// paragraphe par paragraphe.
  static String extractText(Uint8List docxBytes) {
    if (docxBytes.isEmpty) {
      throw const FormatException('Le fichier DOCX est vide.');
    }

    final archive = ZipDecoder().decodeBytes(docxBytes, verify: true);
    final documentFile = archive.files.firstWhere(
      (f) => f.name == _documentXmlPath,
      orElse: () => throw const FormatException(
        'Impossible de lire ce fichier DOCX (document.xml manquant).',
      ),
    );

    final xmlBytes = documentFile.content as List<int>;
    final xmlString = utf8.decode(xmlBytes, allowMalformed: true);
    final xmlDocument = XmlDocument.parse(xmlString);

    final paragraphs = <String>[];
    final paragraphElements = xmlDocument.descendants.whereType<XmlElement>().where(
          (element) => element.name.local == 'p',
        );

    for (final paragraph in paragraphElements) {
      final buffer = StringBuffer();

      for (final element in paragraph.descendants.whereType<XmlElement>()) {
        switch (element.name.local) {
          case 't':
            buffer.write(element.innerText);
            break;
          case 'tab':
            buffer.write('\t');
            break;
          case 'br':
          case 'cr':
            buffer.write('\n');
            break;
          default:
            break;
        }
      }

      final value = buffer.toString().trimRight();
      if (value.isNotEmpty) {
        paragraphs.add(value);
      }
    }

    return paragraphs.join('\n\n').trim();
  }
}
