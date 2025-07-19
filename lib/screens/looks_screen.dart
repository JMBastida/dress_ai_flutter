import 'dart:typed_data';
import 'package:custom_flutter_painter/flutter_painter.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LooksScreen extends StatefulWidget {
  const LooksScreen({super.key});

  @override
  State<LooksScreen> createState() => _LooksScreenState();
}

class _LooksScreenState extends State<LooksScreen> {
  late final PainterController _controller;
  final user = FirebaseAuth.instance.currentUser;
  List<String> _clothingImageUrls = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = PainterController();
    _fetchClothingImages();
  }

 Future<void> _fetchClothingImages() async {
  try {
    final storageRef = FirebaseStorage.instance.ref();
    final result = await storageRef.child('clothes').listAll();

    if (result.items.isEmpty) {
      setState(() {
        _clothingImageUrls = [];
        _loading = false;
      });
      return;
    }

    final urls = await Future.wait(result.items.map((ref) => ref.getDownloadURL()));

    setState(() {
      _clothingImageUrls = urls;
      _loading = false;
    });
  } catch (e) {
    debugPrint('Error cargando imágenes del look: $e');
    setState(() {
      _clothingImageUrls = [];
      _loading = false;
    });
  }
}
  Future<void> _addSticker(String imageUrl) async {
    final image = await NetworkImage(imageUrl).image;
    _controller.addImage(image, const Size(100, 100));
  }

  Future<void> _saveLook() async {
    final image = await _controller.renderImage(const Size(512, 512));
    final bytes = await image.pngBytes;

    final lookRef = FirebaseStorage.instance
        .ref('looks/${user!.uid}/${DateTime.now().millisecondsSinceEpoch}.png');
    await lookRef.putData(bytes!);
    final url = await lookRef.getDownloadURL();

    await FirebaseFirestore.instance.collection('looks').add({
      'uid': user!.uid,
      'imageUrl': url,
      'createdAt': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Look guardado correctamente")));
  }

  void _openStickerPicker() {
    showModalBottomSheet(
      context: context,
      builder: (_) => _clothingImageUrls.isEmpty
          ? const Center(child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text("No hay imágenes disponibles."),
            ))
          : GridView.count(
              crossAxisCount: 3,
              children: _clothingImageUrls.map((url) {
                return InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    _addSticker(url);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.network(url),
                  ),
                );
              }).toList(),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Crear Look"),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveLook,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : FlutterPainter(controller: _controller),
      floatingActionButton: FloatingActionButton(
        onPressed: _openStickerPicker,
        child: const Icon(Icons.add),
      ),
    );
  }
}