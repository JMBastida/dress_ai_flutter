import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ClosetScreen extends StatelessWidget {
  const ClosetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tu Closet')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('clothes')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final clothes = snapshot.data?.docs ?? [];

          if (clothes.isEmpty) {
            return Center(child: Text('No hay prendas aún.'));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemCount: clothes.length,
            itemBuilder: (context, index) {
              final item = clothes[index];
              final imageUrl = item['imageUrl'];
              final fromUrl = item['fromUrl'] ?? false;

              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      loadingBuilder: (context, child, progress) =>
                      progress == null ? child : Center(child: CircularProgressIndicator()),
                      errorBuilder: (context, error, _) => Icon(Icons.error),
                    ),
                  ),
                  if (fromUrl)
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'URL',
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
