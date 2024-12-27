
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddTransactionScreen extends StatefulWidget {
  final String itemId; // ID barang yang dipilih
  final String itemName; // ID barang yang dipilih

  const AddTransactionScreen({Key? key, required this.itemId, required this.itemName})
      : super(key: key);

  @override
  _AddTransactionScreenState createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  String _transactionType = 'in'; // Default transaction type: "Barang Masuk"
  final _quantityController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  int _currentStock = 0; // Stok terkini
  int _stockPreview = 0; // Tambahkan variabel baru untuk stok sementara

  @override
  void initState() {
    super.initState();
    _loadItemData(); // Muat data barang untuk mendapatkan stok terkini
  }

  // Fungsi untuk memuat data barang dari Firestore
  Future<void> _loadItemData() async {
    final docSnapshot = await FirebaseFirestore.instance
        .collection('items')
        .doc(widget.itemId)
        .get();

    if (docSnapshot.exists) {
      final itemData = docSnapshot.data() as Map<String, dynamic>;
      setState(() {
        _currentStock =
            itemData['stock'] ?? 0; // Ambil stok terkini dari Firestore
        _stockPreview = _currentStock; // Set stok preview awal
      });
    }
  }

  // Fungsi untuk menghitung stok sementara berdasarkan input dan jenis transaksi
  void _updateStockPreview() {
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    setState(() {
      if (_transactionType == 'in') {
        _stockPreview = _currentStock + quantity; // Tambah untuk barang masuk
      } else if (_transactionType == 'out') {
        _stockPreview = _currentStock - quantity; // Kurangi untuk barang keluar
      }
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      final quantity = int.parse(_quantityController.text);

      // Validasi stok untuk barang keluar
      if (_transactionType == 'out' && quantity > _currentStock) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Stok tidak mencukupi untuk barang keluar!')),
        );
        return;
      }

      // Simpan transaksi ke Firestore
      final transactionRef =
      FirebaseFirestore.instance.collection('transactions').doc();
      await transactionRef.set({
        'itemId': widget.itemId, // Menyimpan ID item yang terkait
        'type': _transactionType,
        'quantity': quantity,
        'date': _selectedDate,
      });

      // Update stok barang di Firestore
      final updatedStock = _transactionType == 'in'
          ? _currentStock + quantity
          : _currentStock - quantity;
      await FirebaseFirestore.instance
          .collection('items')
          .doc(widget.itemId)
          .update({'stock': updatedStock});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Riwayat transaksi berhasil disimpan!')),
      );

      Navigator.pop(
          context, true); // Kembali ke halaman sebelumnya dengan hasil true
    }
  }

  String _formatSelectedDate() {
    final day = _selectedDate.day.toString().padLeft(2, '0');
    final month = _selectedDate.month.toString().padLeft(2, '0');
    final year = _selectedDate.year;

    return '$day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tambah Riwayat Barang')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    Text(
                      'Barang : ${widget.itemName}',
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _transactionType,
                      decoration: InputDecoration(labelText: 'Jenis Transaksi'),
                      items: [
                        DropdownMenuItem(
                          value: 'in',
                          child: Text('Barang Masuk'),
                        ),
                        DropdownMenuItem(
                          value: 'out',
                          child: Text('Barang Keluar'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _transactionType = value!;
                        });
                        _updateStockPreview(); // Update stok preview setelah jenis transaksi berubah
                      },
                    ),
                    TextFormField(
                      controller: _quantityController,
                      decoration: InputDecoration(labelText: 'Jumlah'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Jumlah tidak boleh kosong';
                        }
                        if (int.tryParse(value) == null ||
                            int.parse(value) <= 0) {
                          return 'Jumlah harus berupa angka positif';
                        }
                        return null;
                      },
                      onChanged: (value) =>
                          _updateStockPreview(), // Update stok preview setelah jumlah berubah
                    ),
                    const SizedBox(height: 30),
                    Text(
                      'Stok Setelah Transaksi: $_stockPreview',
                      style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          'Tanggal: ${_formatSelectedDate()}',
                          style: TextStyle(fontSize: 16),
                        ),
                        Spacer(),
                        ElevatedButton(
                          onPressed: () => _selectDate(context),
                          child: Text('Pilih Tanggal'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saveTransaction,
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50), // Lebar penuh
                ),
                child: Text('Simpan Transaksi'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }
}
