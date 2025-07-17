import 'dart:typed_data';

import 'package:dress_ai/services/tf_lite_segmenter_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/firebase_service.dart';

class ImportUrlScreen extends StatefulWidget {
  @override
  State<ImportUrlScreen> createState() => _ImportUrlScreenState();
}

class _ImportUrlScreenState extends State<ImportUrlScreen> {
  final TextEditingController _controller = TextEditingController();
  List<String> rawUrls = [];
  List<Uint8List> processedImages = [];
  bool isProcessing = false;

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
                final response = await http.get(Uri.parse(url));
        if (response.statusCode != 200) throw Exception('Error al descargar imagen');

        final imageBytes = response.bodyBytes;

        final segmenter = TFLiteSegmenter();
        await segmenter.init();
        final processedImage = await segmenter.runSegmentation(imageBytes);
                processedImages.add(processedImage);
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.png';
        final imageUrl = await uploadToStorage(processedImage, fileName);
        await saveToFirestore(imageUrl, true);
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
