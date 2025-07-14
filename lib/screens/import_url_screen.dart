import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:local_rembg/local_rembg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../services/firebase_service.dart';
import '../services/image_processing_service.dart';

class ImportUrlScreen extends StatefulWidget {
  @override
  State<ImportUrlScreen> createState() => _ImportUrlScreenState();
}

class _ImportUrlScreenState extends State<ImportUrlScreen> {
  final TextEditingController _controller = TextEditingController();
  List<String> rawUrls = [];
  List<Uint8List> processedImages = [];
  bool isProcessing = false;

  Future<File> _downloadImage(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) throw Exception('Error al descargar imagen');

    final tempDir = await getTemporaryDirectory();
    final filePath = p.join(tempDir.path, '${DateTime.now().millisecondsSinceEpoch}.jpg');
    final file = File(filePath);
    return await file.writeAsBytes(response.bodyBytes);
  }

  Future<void> _processUrls() async {
    setState(() {
      isProcessing = true;
      processedImages.clear();
    });

    final urls = _controller.text
        .split('\n')
        .map((e) => e.trim())
        .where((url) => url.startsWith('http'))
        .toList();

    for (String url in urls) {
      try {
        final file = await _downloadImage(url);
        final Uint8List imageBytes = await file.readAsBytes();
        final LocalRembgResultModel result   = await removeBackground(file.path, imageBytes);
        if (result.status == 1 && result.imageBytes != null) {
          final Uint8List processedImage = Uint8List.fromList(result.imageBytes!);

          // Mostrar en UI (opcional)
          processedImages.add(processedImage);

          // Subir a Firebase
          final fileName = '${DateTime.now().millisecondsSinceEpoch}.png';
          final imageUrl = await uploadToStorage(processedImage, fileName);

          // Guardar en Firestore como "imagen desde URL"
          await saveToFirestore(imageUrl, true);
        } else {
          print("❌ Error eliminando fondo: ${result.errorMessage}");
        }
      } catch (e) {
        print("Error procesando $url: $e");
      }
    }

    setState(() {
      isProcessing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Importar desde URL')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("Pega aquí varias URLs de imágenes de prendas:"),
            SizedBox(height: 8),
            TextField(
              controller: _controller,
              maxLines: 6,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'https://example.com/image1.png\nhttps://example.com/image2.jpg',
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: isProcessing ? null : _processUrls,
              child: isProcessing ? CircularProgressIndicator() : Text('Procesar imágenes'),
            ),
            SizedBox(height: 10),
            Expanded(
              child: processedImages.isEmpty
                  ? Center(child: Text('Sin imágenes procesadas.'))
                  : GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
                itemCount: processedImages.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Image.memory(processedImages[index], fit: BoxFit.cover),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
