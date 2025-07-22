import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ClosetScreen extends StatelessWidget {
  const ClosetScreen({super.key});

  @override
  Widget build(BuildContext context) {
            final userId = FirebaseAuth.instance.currentUser?.uid;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Tu Closet'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Prendas'),
              Tab(text: 'Looks'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Prendas
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('clothes')
                  .where('userId', isEqualTo: userId)
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
                    final docId = item.id;
                    final isPublic = item['isPublic'] ?? false;

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
                        Positioned(
                          top: 4,
                          right: 4,
                          child: IconButton(
                            icon: Icon(
                              isPublic ? Icons.public : Icons.public_off,
                              size: 18,
                              color: isPublic ? Colors.green : Colors.grey,
                            ),
                            onPressed: () {
                              FirebaseFirestore.instance.collection('clothes').doc(docId).update({
                                'isPublic': !isPublic,
                              });
                            },
                          ),
                        ),
                                            ],
                    );
                  },
                );
              },
            ),
            // Looks
            Center(
              child: Text("Aquí se mostrarán tus looks"),
            ),
          ],
        ),
      )
      );
  }
  }