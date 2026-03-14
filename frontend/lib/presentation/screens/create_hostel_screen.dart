import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/api_config.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/hostel_provider.dart';
import '../widgets/location_picker_map.dart';

class CreateHostelScreen extends StatefulWidget {
  const CreateHostelScreen({Key? key}) : super(key: key);

  @override
  State<CreateHostelScreen> createState() => _CreateHostelScreenState();
}

class _CreateHostelScreenState extends State<CreateHostelScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _roomsController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  LatLng _selectedLocation = const LatLng(12.9716, 77.5946); // Bangalore default
  String _type = 'coed';
  bool _isLoading = false;
  Future<void> _submitHostel() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final hostelProvider = Provider.of<HostelProvider>(context, listen: false);

    final hostelData = {
      'name': _nameController.text.trim(),
      'description': _descController.text.trim(),
      'address': _addressController.text.trim(),
      'city': _cityController.text.trim(),
      'phone': _phoneController.text.trim(),
      'pricePerNight': double.parse(_priceController.text.trim()),
      'rentPerMonth': double.parse(_priceController.text.trim()) * 30, // Default calculation
      'totalRooms': int.parse(_roomsController.text.trim()),
      'type': _type,
      'location': {
        'lat': _selectedLocation.latitude,
        'lng': _selectedLocation.longitude,
      },
      'facilities': ['WiFi', 'CCTV', 'Security'],
    };

    final success = await hostelProvider.createHostel(hostelData, authProvider.token!);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hostel created successfully!')),
        );
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error creating hostel. Please check your inputs.')),
        );
      }
    }
    
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Create Hostel'),
        backgroundColor: const Color(0xFF0F172A),
        leading: const BackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hostel Details',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _buildTextField(_nameController, 'Hostel Name', Icons.business),
              _buildTextField(_descController, 'Description', Icons.description, maxLines: 3),
              _buildTextField(_addressController, 'Address', Icons.location_on),
              _buildTextField(_cityController, 'City', Icons.location_city),
              _buildTextField(_phoneController, 'Contact Number (10 digits)', Icons.phone,
                  keyboardType: TextInputType.phone,
                  helperText: '⚠️ India: 10 digits required (e.g. 9876543210)'),
              Row(
                children: [
                   Expanded(child: _buildTextField(_priceController, 'Price/Night', Icons.currency_rupee, keyboardType: TextInputType.number)),
                   const SizedBox(width: 16),
                   Expanded(child: _buildTextField(_roomsController, 'Total Rooms', Icons.meeting_room, keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 10),
              const Text('Hostel Type', style: TextStyle(color: Colors.white70)),
              Theme(
                data: ThemeData.dark(),
                child: DropdownButton<String>(
                  value: _type,
                  isExpanded: true,
                  items: ['boys', 'girls', 'coed'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _type = val!),
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'Pin Location',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              LocationPickerMap(
                initialLocation: _selectedLocation,
                onLocationSelected: (loc) => _selectedLocation = loc,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitHostel,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFACC15),
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text('CREATE HOSTEL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon,
      {int maxLines = 1, TextInputType keyboardType = TextInputType.text, String? helperText}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          prefixIcon: Icon(icon, color: const Color(0xFFFACC15)),
          helperText: helperText,
          helperStyle: const TextStyle(color: Colors.orange, fontSize: 11),
          filled: true,
          fillColor: const Color(0xFF1E293B),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFACC15))),
        ),
        validator: (value) => value == null || value.isEmpty ? 'Field required' : null,
      ),
    );
  }
}
