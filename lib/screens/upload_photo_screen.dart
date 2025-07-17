import 'dart:io';
import 'dart:typed_data';
import 'package:dress_ai/services/tf_lite_segmenter_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class UploadPhotoScreen extends StatefulWidget {
  @override
  State<UploadPhotoScreen> createState() => _UploadPhotoScreenState();
}

class _UploadPhotoScreenState extends State<UploadPhotoScreen> {
  File? selectedImage;
  Uint8List? processedImage;
  final TextEditingController _urlController = TextEditingController();
  List<Uint8List> processedImages = [];
  bool isProcessing = false;

  Future<void> _pickImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source);
    if (picked == null) return;

    final file = File(picked.path);

    setState(() {
      selectedImage = file;
      processedImage = null;
    });

    await _processImage(file);
  }

  Future<void> _processImage(File imageFile) async {
    setState(() => isProcessing = true);

    try {
      final Uint8List imageBytes = await imageFile.readAsBytes();
      final segmenter = TFLiteSegmenter();
      await segmenter.init();
      final processedImage = await segmenter.runSegmentation(imageBytes);

      // Subir a Firebase
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.png';
      final ref = FirebaseStorage.instance.ref().child('clothes/$fileName');
      await ref.putData(processedImage, SettableMetadata(contentType: 'image/png'));

      final downloadUrl = await ref.getDownloadURL();

      // Guardar en Firestore
      await FirebaseFirestore.instance.collection('clothes').add({
        'imageUrl': downloadUrl,
        'fromUrl': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        this.processedImage = processedImage;
      });
      
    } catch (e) {
      print("❌ Error: $e");
    } finally {
      setState(() => isProcessing = false);
    }
  }

  Future<void> _processUrls() async {
    final urls = _urlController.text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (urls.isEmpty) return;

    setState(() {
      isProcessing = true;
      processedImages = [];
    });

    final segmenter = TFLiteSegmenter();
    await segmenter.init();

    for (final url in urls) {
      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final Uint8List imageBytes = response.bodyBytes;
          final Uint8List processedImage = await segmenter.runSegmentation(imageBytes);

          // Subir a Firebase
          final fileName = '${DateTime.now().millisecondsSinceEpoch}_${url.hashCode}.png';
          final ref = FirebaseStorage.instance.ref().child('clothes/$fileName');
          await ref.putData(processedImage, SettableMetadata(contentType: 'image/png'));

          final downloadUrl = await ref.getDownloadURL();

          // Guardar en Firestore
          await FirebaseFirestore.instance.collection('clothes').add({
            'imageUrl': downloadUrl,
            'fromUrl': true,
            'createdAt': FieldValue.serverTimestamp(),
          });

          setState(() {
            processedImages.add(processedImage);
          });
        } else {
          print("❌ Failed to download image from $url");
        }
      } catch (e) {
        print("❌ Error processing URL $url: $e");
      }
    }

    setState(() {
      isProcessing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Importar imágenes')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text("Pega aquí varias URLs de imágenes de prendas:"),
            SizedBox(height: 8),
            TextField(
              controller: _urlController,
              maxLines: 6,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'https://example.com/image1.png\nhttps://example.com/image2.jpg',
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: isProcessing ? null : _processUrls,
              child: isProcessing ? CircularProgressIndicator() : Text('Procesar URLs'),
            ),
            const SizedBox(height: 20),
            if (selectedImage != null) ...[
              Text("Imagen original"),
              Image.file(selectedImage!, height: 150),
            ],
            const SizedBox(height: 16),
            if (processedImage != null) ...[
              Text("Imagen procesada"),
              Image.memory(processedImage!, height: 150),
            ],
            if (processedImages.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text("Imágenes procesadas desde URLs"),
              SizedBox(
                height: 150,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: processedImages.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Image.memory(processedImages[index], height: 150),
                    );
                  },
                ),
              ),
            ],
            if (isProcessing && processedImage == null) CircularProgressIndicator(),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(Icons.photo),
              label: Text('Elegir de galería'),
              onPressed: () => _pickImage(ImageSource.gallery),
            ),
            ElevatedButton.icon(
              icon: Icon(Icons.camera_alt),
              label: Text('Tomar foto'),
              onPressed: () => _pickImage(ImageSource.camera),
            ),
          ],
        ),
      ),
    );
  }
}
