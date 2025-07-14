import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

Future<void> saveToFirestore(String imageUrl, bool fromUrl) async {
  await FirebaseFirestore.instance.collection('clothes').add({
    'imageUrl': imageUrl,
    'fromUrl': fromUrl,
    'createdAt': FieldValue.serverTimestamp(),
    // Puedes agregar userId si tienes autenticación
  });
}

Future<String> uploadToStorage(Uint8List imageBytes, String fileName) async {
  final ref = FirebaseStorage.instance.ref().child('clothes/$fileName');
  final uploadTask = await ref.putData(imageBytes, SettableMetadata(contentType: 'image/png'));
  return await ref.getDownloadURL();
}