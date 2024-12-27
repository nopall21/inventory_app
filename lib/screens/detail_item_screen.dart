import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'add_transaction_screen.dart';

class DetailItemScreen extends StatefulWidget {
  final String itemId;

  const DetailItemScreen({Key? key, required this.itemId}) : super(key: key);

  @override
  _DetailItemScreenState createState() => _DetailItemScreenState();
}

class _DetailItemScreenState extends State<DetailItemScreen> {

  // Fungsi untuk menghapus barang
  Future<void> _deleteItem() async {
    await FirebaseFirestore.instance.collection('items').doc(widget.itemId).delete();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Barang berhasil dihapus')),
    );

    Navigator.pop(context, true); // Kembali dengan status perubahan
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Barang'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _deleteItem(),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('items')
            .doc(widget.itemId)
            .snapshots(), // Real-time stream untuk data barang
        builder: (context, itemSnapshot) {
          if (!itemSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final itemData = itemSnapshot.data!.data() as Map<String, dynamic>;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    children: [
                      Image.network(itemData['imageUrl']),
                      const SizedBox(height: 16),

                      Text(
                        itemData['name'],
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        itemData['description'] ?? 'Tidak ada deskripsi',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        'Kategori: ${itemData['category']}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Harga: Rp ${itemData['price'].toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Stok: ${itemData['stock']}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const Divider(),

                      const Text(
                        'Riwayat Transaksi',
                        style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),

                      // StreamBuilder untuk transaksi
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('transactions')
                            .where('itemId', isEqualTo: widget.itemId)
                            .orderBy('date', descending: true)
                            .snapshots(), // Real-time stream untuk transaksi
                        builder: (context, transactionSnapshot) {
                          if (!transactionSnapshot.hasData) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          final transactions = transactionSnapshot.data!.docs;

                          if (transactions.isEmpty) {
                            return const Text('Belum ada riwayat transaksi');
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: transactions.length,
                            itemBuilder: (context, index) {
                              final transaction = transactions[index].data()
                              as Map<String, dynamic>;
                              final timestamp =
                              transaction['date'] as Timestamp;
                              final date = timestamp.toDate();
                              final formattedDate =
                                  "${date.day.toString().padLeft(2, '0')}/"
                                  "${date.month.toString().padLeft(2, '0')}/"
                                  "${date.year}";

                              return ListTile(
                                title: Text(
                                  transaction['type'] == 'in'
                                      ? 'Barang Masuk'
                                      : 'Barang Keluar',
                                ),
                                subtitle: Text(
                                  'Tanggal: $formattedDate\nJumlah: ${transaction['quantity']}',
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AddTransactionScreen(itemId: widget.itemId, itemName: itemData['name']),
                      ),
                    );

                    if (result == true) {
                      // Tidak perlu memuat ulang transaksi karena StreamBuilder otomatis memperbarui.
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Tambah Riwayat Transaksi'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}