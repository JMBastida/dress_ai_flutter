import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_rembg/local_rembg.dart'; // Asegúrate de importar esto
import '../services/image_processing_service.dart';

class UploadPhotoScreen extends StatefulWidget {
  @override
  State<UploadPhotoScreen> createState() => _UploadPhotoScreenState();
}

class _UploadPhotoScreenState extends State<UploadPhotoScreen> {
  File? selectedImage;
  Uint8List? processedImage;
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

      final LocalRembgResultModel result =
      await removeBackground(imageFile.path, imageBytes);

      if (result.status == 1 && result.imageBytes != null) {
        final Uint8List bgRemoved = Uint8List.fromList(result.imageBytes!);

        // Subir a Firebase
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.png';
        final ref = FirebaseStorage.instance.ref().child('clothes/$fileName');
        await ref.putData(bgRemoved, SettableMetadata(contentType: 'image/png'));

        final downloadUrl = await ref.getDownloadURL();

        // Guardar en Firestore
        await FirebaseFirestore.instance.collection('clothes').add({
          'imageUrl': downloadUrl,
          'fromUrl': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        setState(() {
          processedImage = bgRemoved;
        });
      } else {
        print("❌ Falló la eliminación del fondo: ${result.errorMessage}");
      }
    } catch (e) {
      print("❌ Error: $e");
    } finally {
      setState(() => isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Upload from Gallery')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (selectedImage != null) ...[
              Text("Imagen original"),
              Image.file(selectedImage!, height: 150),
            ],
            const SizedBox(height: 16),
            if (processedImage != null) ...[
              Text("Imagen procesada"),
              Image.memory(processedImage!, height: 150),
            ],
            if (isProcessing) CircularProgressIndicator(),
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
