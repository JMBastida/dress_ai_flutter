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
  final List<String> _usedClothingIds = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = PainterController();
    _controller.background = const Color.fromARGB(255, 206, 4, 4).backgroundDrawable;
    _fetchClothingImages();
  }

  Future<void> _fetchClothingImages() async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('clothes')
          .where('userId', isEqualTo: user!.uid)
          .get();

      final urls = query.docs.map((doc) => doc['imageUrl'] as String).toList();

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

    final id = Uri.parse(imageUrl).pathSegments.last.split('.').first;
    if (!_usedClothingIds.contains(id)) {
      _usedClothingIds.add(id);
    }
  }

  Future<void> _saveLook() async {
    setState(() {
      _saving = true;
    });

    try {
      final renderBox = context.findRenderObject() as RenderBox?;
      final size = renderBox?.size ?? const Size(512, 512);

      final image = await _controller.renderImage(
        size,
      );
      final bytes = await image.pngBytes;

      final fileName = '${DateTime.now().millisecondsSinceEpoch}.png';
      final lookRef = FirebaseStorage.instance
          .ref('looks/${user!.uid}/$fileName');
      await lookRef.putData(bytes!);
      final url = await lookRef.getDownloadURL();

      await FirebaseFirestore.instance.collection('looks').add({
        'userId': user!.uid,
        'imageUrl': url,
        'createdAt': FieldValue.serverTimestamp(),
        'usedClothes': _usedClothingIds,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Look guardado correctamente")),
      );
    } catch (e) {
      debugPrint("Error guardando el look: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al guardar el look")),
      );
    } finally {
      setState(() {
        _saving = false;
      });
    }
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
            icon: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            onPressed: _saving ? null : _saveLook,
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