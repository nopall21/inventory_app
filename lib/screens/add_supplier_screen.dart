import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class AddSupplierScreen extends StatefulWidget {
  const AddSupplierScreen({Key? key}) : super(key: key);

  @override
  _AddSupplierScreenState createState() => _AddSupplierScreenState();
}

class _AddSupplierScreenState extends State<AddSupplierScreen> {
  final _formKey = GlobalKey<FormState>();
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  Position? _currentPosition;

  // Fungsi untuk mengambil lokasi supplier
  Future<void> _getLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Memeriksa apakah layanan GPS diaktifkan
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Layanan lokasi tidak aktif')),
      );
      return;
    }

    // Memeriksa izin lokasi
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Izin lokasi ditolak')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Izin lokasi ditolak secara permanen')),
      );
      return;
    }

    // Mendapatkan posisi saat ini
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = position;
    });
  }

  // Fungsi untuk menyimpan data supplier ke Firestore
  Future<void> _saveSupplier() async {
    if (_formKey.currentState!.validate() && _currentPosition != null) {
      final supplierRef = FirebaseFirestore.instance.collection('suppliers');
      await supplierRef.add({
        'userId': userId,
        'name': _nameController.text,
        'address': _addressController.text,
        'contact': _contactController.text,
        'latitude': _currentPosition!.latitude,
        'longitude': _currentPosition!.longitude,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Supplier berhasil ditambahkan')),
      );

      Navigator.pop(context); // Navigasi kembali setelah berhasil
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Harap lengkapi data dengan benar')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tambah Supplier')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Nama Supplier'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama supplier tidak boleh kosong';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(labelText: 'Alamat Supplier'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Alamat supplier tidak boleh kosong';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _contactController,
                decoration: InputDecoration(labelText: 'Kontak Supplier'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Kontak supplier tidak boleh kosong';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _getLocation,
                child: Text('Ambil Lokasi Supplier'),
              ),
              SizedBox(height: 16),
              if (_currentPosition != null)
                Text(
                  'Koordinat: Lat: ${_currentPosition!.latitude}, Long: ${_currentPosition!.longitude}',
                ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saveSupplier,
                child: Text('Simpan Supplier'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}