import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class DetailSupplierScreen extends StatefulWidget {
  final String supplierId;

  const DetailSupplierScreen({Key? key, required this.supplierId})
      : super(key: key);

  @override
  _DetailSupplierScreenState createState() => _DetailSupplierScreenState();
}

class _DetailSupplierScreenState extends State<DetailSupplierScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  LatLng? _supplierLocation; // Lokasi supplier
  bool _isLoading = true; // Status loading data
  GoogleMapController? _mapController; // Controller Google Maps

  @override
  void initState() {
    super.initState();
    _loadSupplierData(); // Memuat data saat pertama kali dibuka
  }

  // Fungsi untuk memuat data supplier dari Firestore
  Future<void> _loadSupplierData() async {
    try {
      DocumentSnapshot supplierDoc = await FirebaseFirestore.instance
          .collection('suppliers')
          .doc(widget.supplierId)
          .get();

      if (supplierDoc.exists) {
        setState(() {
          // Mengambil data dari Firestore
          _nameController.text = supplierDoc['name'];
          _addressController.text = supplierDoc['address'];
          _contactController.text = supplierDoc['contact'];
          double latitude = supplierDoc['latitude'];
          double longitude = supplierDoc['longitude'];
          _supplierLocation = LatLng(latitude, longitude);
          _isLoading = false; // Menghentikan loading
        });

        // Mengarahkan kamera ke lokasi supplier setelah data dimuat
        _moveCameraToLocation(_supplierLocation!);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
      Navigator.pop(
          context); // Kembali ke halaman sebelumnya jika terjadi error
    }
  }

  // Fungsi untuk menggerakkan kamera ke lokasi supplier
  void _moveCameraToLocation(LatLng location) {
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(location, 15), // Zoom ke lokasi
      );
    }
  }

  // Fungsi untuk membuka lokasi di aplikasi Google Maps
  Future<void> _openGoogleMaps(LatLng location) async {
    final Uri googleMapsUri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${location.latitude},${location.longitude}');
    if (await canLaunchUrl(googleMapsUri)) {
      await launchUrl(googleMapsUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat membuka Google Maps')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // Tampilkan loading indikator saat data dimuat
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Supplier')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Informasi Supplier
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nama Supplier'),
                  readOnly: true,
                ),
                TextField(
                  controller: _addressController,
                  decoration:
                  const InputDecoration(labelText: 'Alamat Supplier'),
                  readOnly: true,
                ),
                TextField(
                  controller: _contactController,
                  decoration:
                  const InputDecoration(labelText: 'Kontak Supplier'),
                  readOnly: true,
                ),
                const SizedBox(height: 20),

                // Koordinat Lokasi
                if (_supplierLocation != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Koordinat Lokasi:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Latitude: ${_supplierLocation!.latitude}',
                      ),
                      Text(
                        'Longitude: ${_supplierLocation!.longitude}',
                      ),
                    ],
                  ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Google Maps
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _supplierLocation!,
                zoom: 15, // Zoom default
              ),
              markers: {
                Marker(
                  markerId: const MarkerId('supplierLocation'),
                  position: _supplierLocation!,
                  infoWindow: InfoWindow(
                    title: _nameController.text,
                    snippet: _addressController.text,
                  ),
                ),
              },
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
                _moveCameraToLocation(_supplierLocation!); // Pindahkan kamera
              },
            ),
          ),

          const SizedBox(height: 10),

          // Tombol untuk membuka lokasi di aplikasi Google Maps
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () => _openGoogleMaps(_supplierLocation!),
              child: const Text('Buka Lokasi di Google Maps'),
            ),
          ),
        ],
      ),
    );
  }
}