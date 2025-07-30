import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart'; // For picking images
import 'dart:io'; // For File
import '../services/api_services.dart'; // Import ApiService

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _selectedIncidentType = 'Pothole'; // Default value
  final List<String> _incidentTypes = ['Pothole', 'Collision', 'Roadwork', 'Hazard', 'Traffic Jam'];

  List<File> _mediaFiles = []; // To store selected image/video files
  bool _isLoading = false;

  @override
  void dispose() {
    _latitudeController.dispose();
    _longitudeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickMedia() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile>? pickedFiles = await picker.pickMultipleMedia(); // Allows picking multiple images/videos

    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      setState(() {
        _mediaFiles.addAll(pickedFiles.map((xfile) => File(xfile.path)));
      });
      Fluttertoast.showToast(msg: '${pickedFiles.length} media files selected.');
    }
  }

  void _removeMedia(int index) {
    setState(() {
      _mediaFiles.removeAt(index);
    });
  }

  void _submitReport() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final Map<String, dynamic> response = await ApiService.reportAccident(
          context: context, // Pass context
          latitude: double.parse(_latitudeController.text),
          longitude: double.parse(_longitudeController.text),
          incidentType: _selectedIncidentType,
          description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
          mediaFilePaths: _mediaFiles.map((file) => file.path).toList(),
        );

        if (mounted) {
          Fluttertoast.showToast(
            msg: response['message'] ?? 'Incident reported successfully!',
            backgroundColor: Colors.green,
          );
          // Clear form after successful submission
          _formKey.currentState!.reset();
          _latitudeController.clear();
          _longitudeController.clear();
          _descriptionController.clear();
          setState(() {
            _mediaFiles.clear();
            _selectedIncidentType = 'Pothole'; // Reset to default
          });
        }
      } catch (e) {
        if (mounted) {
          Fluttertoast.showToast(
            msg: 'Failed to report incident: $e',
            backgroundColor: Colors.red,
          );
        }
        print('Error submitting report: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Incident'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Report an Accident or Road Jam',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Provide details about the incident to help other drivers and authorities.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _latitudeController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Latitude',
                          hintText: 'e.g., 12.9716',
                          prefixIcon: Icon(Icons.location_on),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter latitude';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Invalid latitude';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _longitudeController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Longitude',
                          hintText: 'e.g., 77.5946',
                          prefixIcon: Icon(Icons.location_on),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter longitude';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Invalid longitude';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedIncidentType,
                        decoration: const InputDecoration(
                          labelText: 'Incident Type',
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: _incidentTypes.map((String type) {
                          return DropdownMenuItem<String>(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedIncidentType = newValue!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description (Optional)',
                          hintText: 'e.g., Large pothole on the right lane.',
                          prefixIcon: Icon(Icons.description),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _pickMedia,
                        icon: const Icon(Icons.add_photo_alternate),
                        label: const Text('Add Photos/Videos'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.tertiary, // Use tertiary color
                          foregroundColor: Theme.of(context).colorScheme.onTertiary,
                        ),
                      ),
                      if (_mediaFiles.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 10.0),
                          child: Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            children: _mediaFiles.asMap().entries.map((entry) {
                              int idx = entry.key;
                              File file = entry.value;
                              return Chip(
                                label: Text(file.path.split('/').last),
                                deleteIcon: const Icon(Icons.close),
                                onDeleted: () => _removeMedia(idx),
                              );
                            }).toList(),
                          ),
                        ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _submitReport,
                        icon: _isLoading
                            ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : const Icon(Icons.send),
                        label: Text(_isLoading ? 'Submitting...' : 'Submit Report'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.secondary,
                          foregroundColor: Theme.of(context).colorScheme.onSecondary,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}