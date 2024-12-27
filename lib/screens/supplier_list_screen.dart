import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inventoryapp/screens/add_supplier_screen.dart';
import 'package:inventoryapp/screens/detail_supplier_screen.dart';

class SupplierListScreen extends StatelessWidget {
  const SupplierListScreen({Key? key}) : super(key: key);

  // Fungsi untuk menghapus supplier dari Firestore
  Future<void> _deleteSupplier(String supplierId) async {
    try {
      await FirebaseFirestore.instance
          .collection('suppliers')
          .doc(supplierId)
          .delete();
      debugPrint("Supplier dengan ID $supplierId berhasil dihapus.");
    } catch (e) {
      debugPrint("Gagal menghapus supplier: $e");
    }
  }

  Stream<QuerySnapshot> getSuppliers() {
    final String userId = FirebaseAuth.instance.currentUser!.uid;

    return FirebaseFirestore.instance
        .collection('suppliers')
        .where('userId', isEqualTo: userId)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Supplier'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: getSuppliers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
                child: Text('Terjadi kesalahan dalam memuat data.'));
          }

          final suppliers = snapshot.data?.docs ?? [];

          if (suppliers.isEmpty) {
            return const Center(
                child: Text('Belum ada supplier yang ditambahkan.'));
          }

          return ListView.builder(
            itemCount: suppliers.length,
            itemBuilder: (context, index) {
              var supplier = suppliers[index];
              String supplierId = supplier.id;
              String name = supplier['name'];
              String address = supplier['address'];
              String contact = supplier['contact'];

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text(name),
                  subtitle: Text('Alamat: $address\nKontak: $contact'),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          // Menampilkan dialog konfirmasi untuk menghapus
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Konfirmasi Hapus'),
                                content: const Text(
                                    'Apakah Anda yakin ingin menghapus supplier ini?'),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text('Batal'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      _deleteSupplier(supplierId);
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text('Hapus'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    // Navigasi ke halaman detail supplier
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            DetailSupplierScreen(supplierId: supplier.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigasi ke halaman Tambah Supplier
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddSupplierScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
        tooltip: 'Tambah Supplier',
      ),
    );
  }
}