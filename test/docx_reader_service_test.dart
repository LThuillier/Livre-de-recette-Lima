import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livre_de_recettes/services/docx_reader_service.dart';

Uint8List _buildDocxWithDocumentXml(String documentXml) {
  final archive = Archive()
    ..addFile(
      ArchiveFile(
        'word/document.xml',
        utf8.encode(documentXml).length,
        utf8.encode(documentXml),
      ),
    );

  final zipped = ZipEncoder().encode(archive)!;
  return Uint8List.fromList(zipped);
}

Uint8List _buildInvalidDocx() {
  final archive = Archive()
    ..addFile(
      ArchiveFile(
        'word/styles.xml',
        utf8.encode('<styles/>').length,
        utf8.encode('<styles/>'),
      ),
    );

  final zipped = ZipEncoder().encode(archive)!;
  return Uint8List.fromList(zipped);
}

void main() {
  test('extractText retourne le texte des paragraphes', () {
    const xml = '''
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    <w:p><w:r><w:t>Bonjour</w:t></w:r></w:p>
    <w:p>
      <w:r><w:t>Plan</w:t></w:r>
      <w:r><w:tab/></w:r>
      <w:r><w:t>Repas</w:t></w:r>
      <w:r><w:br/></w:r>
      <w:r><w:t>Semaine</w:t></w:r>
    </w:p>
  </w:body>
</w:document>
''';

    final docxBytes = _buildDocxWithDocumentXml(xml);

    final text = DocxReaderService.extractText(docxBytes);

    expect(text, 'Bonjour\n\nPlan\tRepas\nSemaine');
  });

  test('extractText leve une erreur si le document est vide', () {
    expect(
      () => DocxReaderService.extractText(Uint8List(0)),
      throwsA(isA<FormatException>()),
    );
  });

  test('extractText leve une erreur si document.xml est absent', () {
    final docxBytes = _buildInvalidDocx();

    expect(
      () => DocxReaderService.extractText(docxBytes),
      throwsA(isA<FormatException>()),
    );
  });
}
