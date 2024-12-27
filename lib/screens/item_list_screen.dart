import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inventoryapp/screens/add_item_screen.dart';
import 'package:inventoryapp/screens/detail_item_screen.dart'; // Import Firestore

class ItemListScreen extends StatefulWidget {
  @override
  _ItemListScreenState createState() => _ItemListScreenState();
}

class _ItemListScreenState extends State<ItemListScreen> {
  // Referensi koleksi Firestore
  Stream<QuerySnapshot> getItems() {
    final String userId = FirebaseAuth.instance.currentUser!.uid;

    return FirebaseFirestore.instance
        .collection('items')
        .where('userId', isEqualTo: userId)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Barang')),
      body: StreamBuilder<QuerySnapshot>(
        stream: getItems(), // Menggunakan Stream untuk pembaruan real-time
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Belum ada barang.'));
          } else {
            // Mengambil daftar dokumen
            final items = snapshot.data!.docs;

            return ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                // Mengambil data barang dari dokumen
                final item = items[index];
                final itemData = item.data() as Map<String, dynamic>;

                return ListTile(
                  leading: Image.network(itemData['imageUrl']),
                  title: Text(
                    itemData['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Kategori: ${itemData['category']}\n'
                        'Stok: ${itemData['stock']}\n'
                        'Harga: ${itemData['price']}',
                  ),
                  onTap: () async {
                    // Navigasi ke DetailItemScreen dengan data Firestore
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailItemScreen(
                          itemId: item.id, // Kirim ID dokumen
                        ),
                      ),
                    );
                    if (result == true) {
                      setState(() {});
                    }
                  },
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddItemScreen(
                onItemAdded: () {}, // Tidak perlu fetch ulang karena Firestore otomatis diperbarui
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}