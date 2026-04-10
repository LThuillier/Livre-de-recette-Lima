import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:livre_de_recettes/services/docx_reader_service.dart';

/// Ecran simple pour selectionner un DOCX et afficher son contenu texte.
class DocxReaderPage extends StatefulWidget {
  const DocxReaderPage({super.key});

  @override
  State<DocxReaderPage> createState() => _DocxReaderPageState();
}

class _DocxReaderPageState extends State<DocxReaderPage> {
  bool _isLoading = false;
  String? _fileName;
  String? _content;
  String? _error;

  Future<void> _pickAndReadDocx() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['docx'],
        withData: true,
      );

      if (!mounted) return;
      if (result == null) {
        setState(() => _isLoading = false);
        return;
      }

      final file = result.files.single;
      final bytes = file.bytes;

      if (bytes == null) {
        throw const FormatException(
          'Le contenu du fichier est inaccessible. Reessaie avec un autre fichier.',
        );
      }

      final text = DocxReaderService.extractText(bytes);
      setState(() {
        _fileName = file.name;
        _content = text.isEmpty ? '(Aucun texte detecte dans ce document)' : text;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Erreur de lecture DOCX: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final bgColor = isLight ? const Color(0xFFFFF5F7) : const Color(0xFF0F0F0F);
    final textColor = isLight ? Colors.black87 : Colors.white;
    final cardColor = isLight ? Colors.white : const Color(0xFF1A1A1A);
    final accentColor = isLight ? Colors.teal : Colors.tealAccent;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        title: Text(
          'Lecteur DOCX',
          style: TextStyle(color: textColor, fontWeight: FontWeight.w700),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: isLight ? Colors.white : Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onPressed: _isLoading ? null : _pickAndReadDocx,
              icon: const Icon(Icons.description_outlined),
              label: const Text('Choisir un fichier .docx'),
            ),
            const SizedBox(height: 12),
            if (_fileName != null)
              Text(
                'Fichier: $_fileName',
                style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
              ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
              ),
            ],
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isLight ? Colors.pink.shade50 : const Color(0xFF2A2A2A),
                  ),
                ),
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(color: accentColor),
                      )
                    : _content == null
                        ? Text(
                            'Selectionne un document Word pour afficher son contenu.',
                            style: TextStyle(color: textColor.withOpacity(0.7)),
                          )
                        : SingleChildScrollView(
                            child: SelectableText(
                              _content!,
                              style: TextStyle(
                                color: textColor,
                                height: 1.45,
                                fontSize: 15,
                              ),
                            ),
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
