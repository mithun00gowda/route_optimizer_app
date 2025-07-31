import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart'; // For picking images
import 'dart:io'; // For File
import 'package:geolocator/geolocator.dart'; // For current location
import 'package:geocoding/geocoding.dart'; // For geocoding (search place)
import 'package:google_maps_flutter/google_maps_flutter.dart'; // For map picker
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
  final TextEditingController _searchLocationController = TextEditingController(); // New controller for search
  String _selectedIncidentType = 'Pothole'; // Default value
  final List<String> _incidentTypes = ['Pothole', 'Collision', 'Roadwork', 'Hazard', 'Traffic Jam'];

  List<File> _mediaFiles = []; // To store selected image/video files
  bool _isLoading = false;

  LatLng? _pickedMapLatLng; // To store location picked from map

  @override
  void dispose() {
    _latitudeController.dispose();
    _longitudeController.dispose();
    _descriptionController.dispose();
    _searchLocationController.dispose();
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
          _searchLocationController.clear(); // Clear search field too
          setState(() {
            _mediaFiles.clear();
            _selectedIncidentType = 'Pothole'; // Reset to default
            _pickedMapLatLng = null; // Clear picked map location
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

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Fluttertoast.showToast(msg: 'Location permissions are denied.');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        Fluttertoast.showToast(msg: 'Location permissions are permanently denied. Please enable from settings.');
        return;
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _latitudeController.text = position.latitude.toString();
        _longitudeController.text = position.longitude.toString();
        _pickedMapLatLng = null; // Clear map pick if using current location
      });
      Fluttertoast.showToast(msg: 'Current location set.');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to get current location: $e');
      print('Error getting current location: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _searchPlace() async {
    if (_searchLocationController.text.isEmpty) {
      Fluttertoast.showToast(msg: 'Please enter a place to search.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      List<Location> locations = await locationFromAddress(_searchLocationController.text);
      if (locations.isNotEmpty) {
        final location = locations.first;
        setState(() {
          _latitudeController.text = location.latitude.toString();
          _longitudeController.text = location.longitude.toString();
          _pickedMapLatLng = null; // Clear map pick if using search
        });
        Fluttertoast.showToast(msg: 'Location found and set.');
      } else {
        Fluttertoast.showToast(msg: 'No location found for "${_searchLocationController.text}"');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error searching place: $e');
      print('Error searching place: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickLocationOnMap() async {
    final LatLng? result = await showModalBottomSheet<LatLng>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8, // Occupy 80% of screen height
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, controller) {
            LatLng? tempPickedLocation = _pickedMapLatLng ?? LatLng(double.tryParse(_latitudeController.text) ?? 12.9716, double.tryParse(_longitudeController.text) ?? 77.5946);
            Set<Marker> tempMarkers = {};
            if (tempPickedLocation != null) {
              tempMarkers.add(
                Marker(
                  markerId: const MarkerId('picked_location'),
                  position: tempPickedLocation,
                  infoWindow: const InfoWindow(title: 'Selected Location'),
                ),
              );
            }

            return Scaffold(
              appBar: AppBar(
                title: const Text('Pick Location on Map'),
                backgroundColor: Theme.of(context).primaryColor,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: () {
                      Navigator.pop(context, tempPickedLocation); // Return the picked location
                    },
                  ),
                ],
              ),
              body: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: tempPickedLocation,
                      zoom: 14.0,
                    ),
                    onMapCreated: (GoogleMapController mapController) {
                      // You can use this controller if needed, but for a simple pick, it's not strictly necessary.
                    },
                    onTap: (LatLng tappedLatLng) {
                      setState(() { // setState on the parent widget to update the marker
                        tempPickedLocation = tappedLatLng;
                        tempMarkers.clear();
                        tempMarkers.add(
                          Marker(
                            markerId: const MarkerId('picked_location'),
                            position: tempPickedLocation!,
                            infoWindow: const InfoWindow(title: 'Selected Location'),
                          ),
                        );
                      });
                    },
                    markers: tempMarkers,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    zoomControlsEnabled: true,
                  ),
                  Positioned(
                    top: 16.0,
                    left: 16.0,
                    right: 16.0,
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      color: Colors.white.withOpacity(0.8),
                      child: Text(
                        'Tap on the map to select a location. Current: ${tempPickedLocation!.latitude.toStringAsFixed(4)}, ${tempPickedLocation!.longitude.toStringAsFixed(4)}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        _latitudeController.text = result.latitude.toString();
        _longitudeController.text = result.longitude.toString();
        _pickedMapLatLng = result; // Store the picked location
        _searchLocationController.clear(); // Clear search field if map is used
      });
      Fluttertoast.showToast(msg: 'Location picked from map.');
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
                      // Location input options
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _getCurrentLocation,
                              icon: const Icon(Icons.my_location),
                              label: const Text('Current'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _pickLocationOnMap,
                              icon: const Icon(Icons.map),
                              label: const Text('Pick on Map'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _searchLocationController,
                        decoration: InputDecoration(
                          labelText: 'Search Place',
                          hintText: 'e.g., MG Road, Bangalore',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _isLoading
                              ? const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : IconButton(
                            icon: const Icon(Icons.send),
                            onPressed: _searchPlace,
                          ),
                        ),
                        onFieldSubmitted: (value) => _searchPlace(), // Trigger search on submit
                      ),
                      const SizedBox(height: 16),
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
