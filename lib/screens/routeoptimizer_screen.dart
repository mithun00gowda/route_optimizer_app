// lib/screens/routeoptimizer_screen.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/gestures.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geocoding/geocoding.dart'; // Import geocoding

import '../models/models.dart';
import '../services/api_services.dart';

enum LocationSelectionState {
  selectingStart,
  selectingEnd,
  none,
}

class RouteOptimizerScreen extends StatefulWidget {
  const RouteOptimizerScreen({super.key});

  @override
  State<RouteOptimizerScreen> createState() => _RouteOptimizerScreenState();
}

class _RouteOptimizerScreenState extends State<RouteOptimizerScreen> {
  final _formKey = GlobalKey<FormState>();
  GoogleMapController? _googleMapController;
  final Completer<GoogleMapController> _mapControllerCompleter = Completer();

  LatLng? _startLatLng;
  LatLng? _endLatLng;
  LocationSelectionState _selectionState = LocationSelectionState.none;

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  bool _isLoading = false;
  RoutePredictionResult? _predictionResult;
  String? _errorMessage;

  String _selectedVehicleType = 'car';
  final List<String> _vehicleTypes = ['car', 'motorcycle', 'truck', 'bus'];
  final TextEditingController _histStartYearController = TextEditingController(text: '${DateTime.now().year - 5}');
  final TextEditingController _histEndYearController = TextEditingController(text: '${DateTime.now().year - 1}');

  // New controllers for displaying location names and search input
  final TextEditingController _startLocationNameController = TextEditingController();
  final TextEditingController _endLocationNameController = TextEditingController();
  final TextEditingController _searchDestinationController = TextEditingController();

  // Flags to indicate if location is set by helper methods
  bool _isStartLocationSetByHelper = false;
  bool _isEndLocationSetByHelper = false;


  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(12.9716, 77.5946), // Bangalore, India
    zoom: 12.0,
  );

  @override
  void initState() {
    super.initState();
    _determinePosition(); // Get current location as default start
  }

  @override
  void dispose() {
    _googleMapController?.dispose();
    _histStartYearController.dispose();
    _histEndYearController.dispose();
    _startLocationNameController.dispose();
    _endLocationNameController.dispose();
    _searchDestinationController.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapControllerCompleter.complete(controller);
    _googleMapController = controller;
    if (_startLatLng != null) {
      _googleMapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_startLatLng!, 15.0),
      );
    }
  }

  Future<void> _updateLocationFields(LatLng latLng, {bool isStart = true, String? locationName}) async {
    setState(() {
      if (isStart) {
        _startLatLng = latLng;
        _markers.removeWhere((m) => m.markerId.value == 'start_point');
        _markers.add(
          Marker(
            markerId: const MarkerId('start_point'),
            position: _startLatLng!,
            infoWindow: InfoWindow(title: locationName ?? 'Start Point'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          ),
        );
        _isStartLocationSetByHelper = true;
      } else {
        _endLatLng = latLng;
        _markers.removeWhere((m) => m.markerId.value == 'end_point');
        _markers.add(
          Marker(
            markerId: const MarkerId('end_point'),
            position: _endLatLng!,
            infoWindow: InfoWindow(title: locationName ?? 'End Point'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        );
        _isEndLocationSetByHelper = true;
      }
    });

    if (locationName == null) {
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(latLng.latitude, latLng.longitude);
        if (placemarks.isNotEmpty) {
          final placemark = placemarks.first;
          final address = "${placemark.street}, ${placemark.locality}, ${placemark.administrativeArea}";
          setState(() {
            if (isStart) {
              _startLocationNameController.text = address;
            } else {
              _endLocationNameController.text = address;
            }
          });
        }
      } catch (e) {
        print('Reverse geocoding failed: $e');
        Fluttertoast.showToast(msg: 'Could not get address for selected point.');
      }
    } else {
      setState(() {
        if (isStart) {
          _startLocationNameController.text = locationName;
        } else {
          _endLocationNameController.text = locationName;
        }
      });
    }
  }


  void _onMapTap(LatLng tappedLatLng) async {
    if (_selectionState == LocationSelectionState.selectingStart) {
      await _updateLocationFields(tappedLatLng, isStart: true, locationName: 'Picked Start Point');
      setState(() {
        _selectionState = LocationSelectionState.none;
      });
      Fluttertoast.showToast(msg: 'Start point set. Select End Point or Get Routes.');
    } else if (_selectionState == LocationSelectionState.selectingEnd) {
      await _updateLocationFields(tappedLatLng, isStart: false, locationName: 'Picked End Point');
      setState(() {
        _selectionState = LocationSelectionState.none;
      });
      Fluttertoast.showToast(msg: 'End point set. You can now get routes.');
    } else {
      if (_googleMapController != null) {
        final double currentZoom = await _googleMapController!.getZoomLevel();
        _googleMapController!.animateCamera(
          CameraUpdate.newLatLngZoom(tappedLatLng, currentZoom),
        );
      } else {
        Fluttertoast.showToast(msg: 'Map not ready yet.');
      }
    }
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    setState(() { _isLoading = true; });

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Fluttertoast.showToast(msg: 'Location services are disabled. Please enable them.');
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Fluttertoast.showToast(msg: 'Location permissions are denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Fluttertoast.showToast(msg: 'Location permissions are permanently denied, we cannot request permissions.');
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      final currentLatLng = LatLng(position.latitude, position.longitude);

      await _updateLocationFields(currentLatLng, isStart: true, locationName: 'Your Current Location');
      _googleMapController?.animateCamera(
        CameraUpdate.newLatLngZoom(currentLatLng, 15.0),
      );
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error getting location: $e');
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _searchDestinationPlace() async {
    if (_searchDestinationController.text.isEmpty) {
      Fluttertoast.showToast(msg: 'Please enter a place to search for destination.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      List<Location> locations = await locationFromAddress(_searchDestinationController.text);
      if (locations.isNotEmpty) {
        final location = locations.first;
        final LatLng foundLatLng = LatLng(location.latitude, location.longitude);
        await _updateLocationFields(foundLatLng, isStart: false, locationName: _searchDestinationController.text);
        Fluttertoast.showToast(msg: 'Destination found and set.');
      } else {
        Fluttertoast.showToast(msg: 'No location found for "${_searchDestinationController.text}"');
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

  void _clearStartLocation() {
    setState(() {
      _startLatLng = null;
      _startLocationNameController.clear();
      _markers.removeWhere((m) => m.markerId.value == 'start_point');
      _isStartLocationSetByHelper = false;
    });
    Fluttertoast.showToast(msg: 'Start location cleared.');
  }

  void _clearEndLocation() {
    setState(() {
      _endLatLng = null;
      _endLocationNameController.clear();
      _searchDestinationController.clear();
      _markers.removeWhere((m) => m.markerId.value == 'end_point');
      _isEndLocationSetByHelper = false;
    });
    Fluttertoast.showToast(msg: 'End location cleared.');
  }


  Future<void> _getRoutes() async {
    FocusScope.of(context).unfocus(); // Close the keyboard

    if (_startLatLng == null || _endLatLng == null) {
      Fluttertoast.showToast(msg: 'Please select both start and end points.');
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _polylines.clear();
      _predictionResult = null;
      _errorMessage = null;
      _markers.retainWhere((m) => m.markerId.value == 'start_point' || m.markerId.value == 'end_point');
    });

    try {
      final result = await ApiService.getRoutePrediction(
        context: context,
        startLat: _startLatLng!.latitude,
        startLon: _startLatLng!.longitude,
        endLat: _endLatLng!.latitude,
        endLon: _endLatLng!.longitude,
        vehicleType: _selectedVehicleType,
        histStartYear: int.parse(_histStartYearController.text),
        histEndYear: int.parse(_histEndYearController.text),
      );

      setState(() {
        _predictionResult = result;

        for (var route in result.allRoutes) {
          _polylines.add(
            Polyline(
              polylineId: PolylineId('route_${route.routeId}'),
              points: route.geometryCoords.map((c) => c.toLatLng()).toList(),
              color: route.routeId == result.bestRoute.routeId ? Colors.blue.shade700 : Colors.grey.withOpacity(0.6),
              width: route.routeId == result.bestRoute.routeId ? 6 : 4,
              zIndex: route.routeId == result.bestRoute.routeId ? 2 : 1,
              patterns: route.routeId != result.bestRoute.routeId ? [PatternItem.dash(10), PatternItem.gap(10)] : [],
            ),
          );
        }

        _markers.addAll(result.simulatedCurrentAccidents.map((accident) =>
            Marker(
              markerId: MarkerId('current_accident_${accident.id}'),
              position: accident.toLatLng(),
              infoWindow: InfoWindow(
                title: 'Accident (${accident.severity?.toUpperCase() ?? 'N/A'})',
                snippet: 'Type: ${accident.type ?? 'N/A'}, Delay: ${accident.simulatedDelayMinutes?.toStringAsFixed(1) ?? 'N/A'} min',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
            )));

        _markers.addAll(result.simulatedHistoricalAccidents.map((accident) =>
            Marker(
              markerId: MarkerId('hist_accident_${accident.id}'),
              position: accident.toLatLng(),
              infoWindow: InfoWindow(
                title: 'Historical Acc. (${accident.severity?.toUpperCase() ?? 'N/A'})',
                snippet: 'Type: ${accident.type ?? 'N/A'} (${accident.year ?? 'N/A'}, ${accident.locationName ?? 'N/A'})',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
            )));
      });

      _fitMapToRouteBounds(result);

    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
      Fluttertoast.showToast(msg: 'Failed to get routes: $_errorMessage');
      print("Error in _getRoutes: $e");
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  void _fitMapToRouteBounds(RoutePredictionResult result) {
    if (_googleMapController == null) return;

    double minLat = double.infinity;
    double minLon = double.infinity;
    double maxLat = double.negativeInfinity;
    double maxLon = double.negativeInfinity;

    void updateBounds(LatLng point) {
      minLat = min(minLat, point.latitude);
      minLon = min(minLon, point.longitude);
      maxLat = max(maxLat, point.latitude);
      maxLon = max(maxLon, point.longitude);
    }

    if (_startLatLng != null) updateBounds(_startLatLng!);
    if (_endLatLng != null) updateBounds(_endLatLng!);

    for (var route in result.allRoutes) {
      for (var coord in route.geometryCoords) {
        updateBounds(coord.toLatLng());
      }
    }
    for (var accident in result.simulatedCurrentAccidents) {
      updateBounds(accident.toLatLng());
    }
    for (var histAccident in result.simulatedHistoricalAccidents) {
      updateBounds(histAccident.toLatLng());
    }


    if (minLat.isInfinite || minLon.isInfinite || maxLat.isInfinite || maxLon.isInfinite) {
      _googleMapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_startLatLng ?? _initialCameraPosition.target, 10.0),
      );
      return;
    }

    final LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(minLat, minLon),
      northeast: LatLng(maxLat, maxLon),
    );

    _googleMapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50.0),
    );
  }

  Future<void> _launchGoogleMapsNavigation() async {
    if (_startLatLng == null || _endLatLng == null) {
      Fluttertoast.showToast(msg: 'Please select both start and end points for navigation.');
      return;
    }

    final String origin = '${_startLatLng!.latitude},${_startLatLng!.longitude}';
    final String destination = '${_endLatLng!.latitude},${_endLatLng!.longitude}';
    final String travelMode = _selectedVehicleType == 'car' ? 'driving' : _selectedVehicleType;

    final Uri googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$destination&travelmode=$travelMode&dir_action=navigate',
    );

    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else {
      Fluttertoast.showToast(msg: 'Could not launch Google Maps. Please ensure the app is installed.');
      print('Could not launch $googleMapsUrl');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OptiRoute: Smart Navigation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () {
              setState(() {
                _startLatLng = null;
                _endLatLng = null;
                _markers.clear();
                _polylines.clear();
                _predictionResult = null;
                _errorMessage = null;
                _selectionState = LocationSelectionState.none;
                _startLocationNameController.clear();
                _endLocationNameController.clear();
                _searchDestinationController.clear();
                _isStartLocationSetByHelper = false;
                _isEndLocationSetByHelper = false;
              });
              Fluttertoast.showToast(msg: 'Map cleared. Select points.');
              _googleMapController?.animateCamera(
                CameraUpdate.newCameraPosition(_initialCameraPosition),
              );
            },
            tooltip: 'Clear Map',
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            onMapCreated: _onMapCreated,
            initialCameraPosition: _initialCameraPosition,
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
            onTap: _onMapTap,

            gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
              Factory<PanGestureRecognizer>(() => PanGestureRecognizer()),
              Factory<ScaleGestureRecognizer>(() => ScaleGestureRecognizer()),
              Factory<TapGestureRecognizer>(() => TapGestureRecognizer()),
              Factory<VerticalDragGestureRecognizer>(() => VerticalDragGestureRecognizer()),
              Factory<HorizontalDragGestureRecognizer>(() => HorizontalDragGestureRecognizer()),
            },
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.9),
              padding: const EdgeInsets.all(8.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Start Location Input
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _startLocationNameController,
                            readOnly: _isStartLocationSetByHelper, // Make read-only if set by helper
                            decoration: InputDecoration(
                              labelText: 'Start Location',
                              hintText: 'Tap on map or use buttons',
                              prefixIcon: const Icon(Icons.location_on),
                              suffixIcon: _isStartLocationSetByHelper
                                  ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: _clearStartLocation,
                              )
                                  : null,
                            ),
                            validator: (value) {
                              if (_startLatLng == null) {
                                return 'Please select a start location.';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          children: [
                            ElevatedButton(
                              onPressed: _isLoading ? null : _determinePosition,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.all(12),
                                minimumSize: const Size(48, 48), // Ensure button is not too small
                              ),
                              child: const Icon(Icons.my_location),
                            ),
                            const SizedBox(height: 4),
                            ElevatedButton(
                              onPressed: _isLoading || _selectionState == LocationSelectionState.selectingStart ? null : () {
                                setState(() {
                                  _selectionState = LocationSelectionState.selectingStart;
                                });
                                Fluttertoast.showToast(msg: 'Tap on map to select Start Point.');
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.all(12),
                                minimumSize: const Size(48, 48),
                                backgroundColor: _selectionState == LocationSelectionState.selectingStart ? Colors.blue.shade100 : null,
                              ),
                              child: const Icon(Icons.map),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // End Location Input
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _endLocationNameController,
                            readOnly: _isEndLocationSetByHelper, // Make read-only if set by helper
                            decoration: InputDecoration(
                              labelText: 'End Location',
                              hintText: 'Tap on map or search place',
                              prefixIcon: const Icon(Icons.flag),
                              suffixIcon: _isEndLocationSetByHelper
                                  ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: _clearEndLocation,
                              )
                                  : null,
                            ),
                            validator: (value) {
                              if (_endLatLng == null) {
                                return 'Please select an end location.';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          children: [
                            ElevatedButton(
                              onPressed: _isLoading ? null : _searchDestinationPlace,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.all(12),
                                minimumSize: const Size(48, 48),
                              ),
                              child: const Icon(Icons.search),
                            ),
                            const SizedBox(height: 4),
                            ElevatedButton(
                              onPressed: _isLoading || _selectionState == LocationSelectionState.selectingEnd ? null : () {
                                setState(() {
                                  _selectionState = LocationSelectionState.selectingEnd;
                                });
                                Fluttertoast.showToast(msg: 'Tap on map to select End Point.');
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.all(12),
                                minimumSize: const Size(48, 48),
                                backgroundColor: _selectionState == LocationSelectionState.selectingEnd ? Colors.blue.shade100 : null,
                              ),
                              child: const Icon(Icons.map),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Search Destination Text Field (optional, if user wants to type directly)
                    if (!_isEndLocationSetByHelper) // Only show if not set by other means
                      TextFormField(
                        controller: _searchDestinationController,
                        decoration: InputDecoration(
                          labelText: 'Search Destination by Name',
                          hintText: 'e.g., Eiffel Tower, Paris',
                          prefixIcon: const Icon(Icons.location_searching),
                          suffixIcon: _isLoading
                              ? const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : IconButton(
                            icon: const Icon(Icons.send),
                            onPressed: _searchDestinationPlace,
                          ),
                        ),
                        onFieldSubmitted: (value) => _searchDestinationPlace(),
                      ),
                    const SizedBox(height: 10),

                    DropdownButtonFormField<String>(
                      value: _selectedVehicleType,
                      decoration: const InputDecoration(
                          labelText: 'Vehicle Type', border: OutlineInputBorder()),
                      items: _vehicleTypes.map((String type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedVehicleType = newValue!;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _histStartYearController,
                            decoration: const InputDecoration(labelText: 'Hist Start Year', border: OutlineInputBorder()),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value!.isEmpty) return 'Enter year';
                              if (int.tryParse(value) == null) return 'Invalid year';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _histEndYearController,
                            decoration: const InputDecoration(labelText: 'Hist End Year', border: OutlineInputBorder()),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value!.isEmpty) return 'Enter year';
                              if (int.tryParse(value) == null) return 'Invalid year';
                              int startYear = int.tryParse(_histStartYearController.text) ?? 0;
                              int endYear = int.tryParse(value) ?? 0;
                              if (endYear < startYear) return 'End year must be >= start year';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _getRoutes,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: const Text(
                        'Get Optimized Routes',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_predictionResult != null && !_isLoading)
            DraggableScrollableSheet(
              initialChildSize: 0.25,
              minChildSize: 0.1,
              maxChildSize: 0.9,
              expand: false,
              builder: (BuildContext context, ScrollController scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(8.0),
                  child: ListView(
                    controller: scrollController,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Best Route (${_predictionResult!.vehicleType.toUpperCase()}):',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const Divider(),
                              Text(
                                'Adjusted Duration: ${_predictionResult!.bestRoute.adjustedDurationMinutes.toStringAsFixed(2)} min',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              Text(
                                'Total Distance: ${(_predictionResult!.bestRoute.totalDistanceMeters / 1000).toStringAsFixed(2)} km',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              Text(
                                'Predicted Severity: ${_predictionResult!.bestRoute.predictedSeverity ?? 'N/A'}',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              Text(
                                'Score: ${_predictionResult!.bestRoute.score.toStringAsFixed(1)}',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Detailed Impacts:',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              ..._predictionResult!.bestRoute.detailedImpacts.entries.map((entry) =>
                                  Text('${entry.key.replaceAll('_', ' ')}: ${entry.value}')).toList(),
                            ],
                          ),
                        ),
                      ),
                      if (_predictionResult!.notBestRoute != null)
                        Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Alternative Route:',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.secondary,
                                  ),
                                ),
                                const Divider(),
                                Text(
                                  'Adjusted Duration: ${_predictionResult!.notBestRoute!.adjustedDurationMinutes.toStringAsFixed(2)} min',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                Text(
                                  'Total Distance: ${(_predictionResult!.notBestRoute!.totalDistanceMeters / 1000).toStringAsFixed(2)} km',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                Text(
                                  'Predicted Severity: ${_predictionResult!.notBestRoute!.predictedSeverity ?? 'N/A'}',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                Text(
                                  'Score: ${_predictionResult!.notBestRoute!.score.toStringAsFixed(1)}',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Detailed Impacts:',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                ..._predictionResult!.notBestRoute!.detailedImpacts.entries.map((entry) =>
                                    Text('${entry.key.replaceAll('_', ' ')}: ${entry.value}')).toList(),
                              ],
                            ),
                          ),
                        ),
                      if (_startLatLng != null && _endLatLng != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _launchGoogleMapsNavigation,
                              icon: const Icon(Icons.navigation),
                              label: const Text('Open in Google Maps App'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade700,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                textStyle: const TextStyle(fontSize: 18),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Text(
                        'Comprehensive Analysis:',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (_predictionResult!.simulatedCurrentAccidents.isNotEmpty)
                        Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Current Incidents:',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const Divider(),
                                ..._predictionResult!.simulatedCurrentAccidents.map((accident) => Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Type: ${accident.type ?? 'N/A'} (Severity: ${accident.severity ?? 'N/A'})'),
                                    Text('Location: ${accident.latitude?.toStringAsFixed(4) ?? 'N/A'}, ${accident.longitude?.toStringAsFixed(4) ?? 'N/A'}'),
                                    Text('Delay: ${accident.simulatedDelayMinutes?.toStringAsFixed(1) ?? 'N/A'} min'),
                                    Text('Description: ${accident.description ?? 'N/A'}'),
                                    const SizedBox(height: 8),
                                  ],
                                )).toList(),
                              ],
                            ),
                          ),
                        ),
                      if (_predictionResult!.simulatedHistoricalAccidents.isNotEmpty)
                        Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Historical Incidents (${_predictionResult!.historicalYearRange.first.toString() ?? 'N/A'}-${_predictionResult!.historicalYearRange.last.toString() ?? 'N/A'}):',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const Divider(),
                                ..._predictionResult!.simulatedHistoricalAccidents.map((accident) => Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Type: ${accident.type ?? 'N/A'} (Severity: ${accident.severity ?? 'N/A'})'),
                                    Text('Location: ${accident.locationName ?? 'N/A'} (${accident.year ?? 'N/A'})'),
                                    Text('Vehicles Involved: ${accident.involvedVehicleType ?? 'N/A'}'),
                                    Text('Incident Count: ${accident.simulatedIncidentCount?.toString() ?? 'N/A'}'),
                                    Text('Date: ${accident.date ?? 'N/A'}'),
                                    Text('Description: ${accident.description ?? 'N/A'}'),
                                    const SizedBox(height: 8),
                                  ],
                                )).toList(),
                              ],
                            ),
                          ),
                        ),
                      if (_predictionResult!.allRoutes.length > 2)
                        Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'All Routes Overview:',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const Divider(),
                                ..._predictionResult!.allRoutes.map((route) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Route ID: ${route.routeId ?? 'N/A'}'),
                                      Text('Adjusted Duration: ${route.adjustedDurationMinutes?.toStringAsFixed(2) ?? 'N/A'} min'),
                                      Text('Score: ${route.score?.toStringAsFixed(1) ?? 'N/A'}'),
                                      const SizedBox(height: 4),
                                    ],
                                  ),
                                )).toList(),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          if (_errorMessage != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 10,
              right: 10,
              child: Container(
                color: Colors.red.withOpacity(0.8),
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
