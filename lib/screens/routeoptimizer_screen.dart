// lib/screens/routeoptimizer_screen.dart

import 'dart:async';
import 'dart:math'; // For min/max in _fitMapToRouteBounds
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/gestures.dart'; // For gestureRecognizers
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Adjust imports based on your file structure
import '../models/models.dart';
import '../services/api_services.dart';

// Define the enum outside the class if it's used globally
enum LocationSelectionState {
  selectingStart,
  selectingEnd,
  none,
}

class RouteOptimizerScreen extends StatefulWidget { // Renamed from RouteScreen to match your error path
  const RouteOptimizerScreen({super.key});

  @override
  State<RouteOptimizerScreen> createState() => _RouteOptimizerScreenState();
}

class _RouteOptimizerScreenState extends State<RouteOptimizerScreen> {
  final _formKey = GlobalKey<FormState>(); // Added back for input validation
  GoogleMapController? _googleMapController;
  final Completer<GoogleMapController> _mapControllerCompleter = Completer(); // Renamed to avoid confusion with the global _mapController

  LatLng? _startLatLng;
  LatLng? _endLatLng;
  LocationSelectionState _selectionState = LocationSelectionState.none;

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  bool _isLoading = false;
  RoutePredictionResult? _predictionResult; // To display results
  String? _errorMessage;

  // Added back TextControllers for vehicle and historical year inputs
  String _selectedVehicleType = 'car';
  final List<String> _vehicleTypes = ['car', 'motorcycle', 'truck', 'bus'];
  final TextEditingController _histStartYearController = TextEditingController(text: '${DateTime.now().year - 5}');
  final TextEditingController _histEndYearController = TextEditingController(text: '${DateTime.now().year - 1}');


  // Initial camera position (can be set to a default or user's current location)
  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(12.9716, 77.5946), // Bangalore, India
    zoom: 12.0,
  );

  @override
  void initState() {
    super.initState();
    // Potentially get current location here if you want to start there
    _determinePosition(); // This will set _startLatLng if location permission granted
  }

  @override
  void dispose() {
    _googleMapController?.dispose();
    _histStartYearController.dispose(); // Dispose controllers
    _histEndYearController.dispose();
    super.dispose();
  }

  // --- Map Callbacks ---
  void _onMapCreated(GoogleMapController controller) {
    _mapControllerCompleter.complete(controller);
    _googleMapController = controller;
    // If startLatLng is already set (e.g., from _determinePosition),
    // move camera to it once map is ready
    if (_startLatLng != null) {
      _googleMapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_startLatLng!, 15.0),
      );
    }
  }

  void _onMapTap(LatLng tappedLatLng) async { // <-- Keep this 'async'
    // First, handle the selection state, which doesn't require async logic
    // or getting the zoom level immediately.
    if (_selectionState == LocationSelectionState.selectingStart) {
      setState(() { // This setState is fine as it's purely synchronous updates
        _startLatLng = tappedLatLng;
        _markers.removeWhere((m) => m.markerId.value == 'start_point');
        _markers.add(
          Marker(
            markerId: const MarkerId('start_point'),
            position: _startLatLng!,
            infoWindow: const InfoWindow(title: 'Start Point (Tap to change)'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          ),
        );
        _selectionState = LocationSelectionState.none;
        Fluttertoast.showToast(msg: 'Start point set. Select End Point or Get Routes.');
      });
    } else if (_selectionState == LocationSelectionState.selectingEnd) {
      setState(() { // This setState is fine
        _endLatLng = tappedLatLng;
        _markers.removeWhere((m) => m.markerId.value == 'end_point');
        _markers.add(
          Marker(
            markerId: const MarkerId('end_point'),
            position: _endLatLng!,
            infoWindow: const InfoWindow(title: 'End Point (Tap to change)'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        );
        _selectionState = LocationSelectionState.none;
        Fluttertoast.showToast(msg: 'End point set. You can now get routes.');
      });
    } else {
      // If not in selection mode, handle the map animation.
      // This part requires awaiting, so it must be outside the setState where possible.
      if (_googleMapController != null) {
        // Await the zoom level here, *before* calling setState.
        final double currentZoom = await _googleMapController!.getZoomLevel();

        setState(() { // Now, this setState is purely for UI updates with resolved values
          _googleMapController!.animateCamera(
            CameraUpdate.newLatLngZoom(tappedLatLng, currentZoom),
          );
        });
      } else {
        Fluttertoast.showToast(msg: 'Map not ready yet.');
      }
    }
  }

  // --- Location and Route Logic ---

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

      setState(() {
        _startLatLng = currentLatLng; // Automatically set current location as start
        _markers.removeWhere((m) => m.markerId.value == 'start_point');
        _markers.add(
          Marker(
            markerId: const MarkerId('start_point'),
            position: currentLatLng,
            infoWindow: const InfoWindow(title: 'Your Current Location'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          ),
        );
      });
      _googleMapController?.animateCamera(
        CameraUpdate.newLatLngZoom(currentLatLng, 15.0),
      );
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error getting location: $e');
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _getRoutes() async {
    if (_startLatLng == null || _endLatLng == null) {
      Fluttertoast.showToast(msg: 'Please select both start and end points.');
      return;
    }
    if (!_formKey.currentState!.validate()) { // Validate year inputs
      return;
    }

    setState(() {
      _isLoading = true;
      _polylines.clear();
      _predictionResult = null;
      _errorMessage = null;
      // Keep start/end markers, clear other dynamic markers
      _markers.retainWhere((m) => m.markerId.value == 'start_point' || m.markerId.value == 'end_point');
    });

    try {
      // Corrected method name to getRoutePrediction and added missing parameters
      final result = await ApiService.getRoutePrediction(
        startLat: _startLatLng!.latitude,
        startLon: _startLatLng!.longitude,
        endLat: _endLatLng!.latitude,
        endLon: _endLatLng!.longitude,
        vehicleType: _selectedVehicleType,
        histStartYear: int.parse(_histStartYearController.text),
        histEndYear: int.parse(_histEndYearController.text),
      );

      setState(() {
        _predictionResult = result; // Store result for display

        // Draw all routes (faded for non-best, prominent for best)
        for (var route in result.allRoutes) {
          _polylines.add(
            Polyline(
              polylineId: PolylineId('route_${route.routeId}'),
              points: route.geometryCoords.map((c) => c.toLatLng()).toList(),
              color: route.routeId == result.bestRoute.routeId ? Colors.blue.shade700 : Colors.grey.withOpacity(0.6),
              width: route.routeId == result.bestRoute.routeId ? 6 : 4,
              zIndex: route.routeId == result.bestRoute.routeId ? 2 : 1, // Best route on top
              patterns: route.routeId != result.bestRoute.routeId ? [PatternItem.dash(10), PatternItem.gap(10)] : [], // Dashed for others
            ),
          );
        }

        // Add current accident markers
        _markers.addAll(result.simulatedCurrentAccidents.map((accident) =>
            Marker(
              markerId: MarkerId('current_accident_${accident.id}'),
              position: accident.toLatLng(),
              infoWindow: InfoWindow(
                title: 'Accident (${accident.severity.toUpperCase()})',
                snippet: 'Type: ${accident.type}, Delay: ${accident.simulatedDelayMinutes.toStringAsFixed(1)} min',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
            )));

        // Add historical accident markers
        _markers.addAll(result.simulatedHistoricalAccidents.map((accident) =>
            Marker(
              markerId: MarkerId('hist_accident_${accident.id}'),
              position: accident.toLatLng(),
              infoWindow: InfoWindow(
                title: 'Historical Acc. (${accident.severity.toUpperCase()})',
                snippet: 'Type: ${accident.type} (${accident.year}, ${accident.locationName})',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
            )));
      });

      // Fit map to bounds after results are available
      _fitMapToRouteBounds(result);

    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
      Fluttertoast.showToast(msg: 'Failed to get routes: $_errorMessage');
      print("Error in _getRoutes: $e"); // For debugging
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  // --- Fit map to bounds (from previous solution) ---
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

    // Ensure start/end points are included (they might be null before route calculation)
    if (_startLatLng != null) updateBounds(_startLatLng!);
    if (_endLatLng != null) updateBounds(_endLatLng!);

    // Include all route coordinates
    for (var route in result.allRoutes) {
      for (var coord in route.geometryCoords) {
        updateBounds(coord.toLatLng());
      }
    }
    // Include all accident locations
    for (var accident in result.simulatedCurrentAccidents) {
      updateBounds(accident.toLatLng());
    }
    for (var histAccident in result.simulatedHistoricalAccidents) {
      updateBounds(histAccident.toLatLng());
    }

    if (minLat.isInfinite || minLon.isInfinite || maxLat.isInfinite || maxLon.isInfinite) {
      // Fallback if no valid points to form bounds, e.g., if lists were empty
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OptiRoute: Smart Navigation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _isLoading ? null : _determinePosition,
            tooltip: 'Use Current Location as Start',
          ),
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
            onTap: _onMapTap, // Crucial for manual point selection

            // Ensure full scroll/zoom functionality, even if nested
            gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
              Factory<PanGestureRecognizer>(() => PanGestureRecognizer()),
              Factory<ScaleGestureRecognizer>(() => ScaleGestureRecognizer()),
              Factory<TapGestureRecognizer>(() => TapGestureRecognizer()),
              Factory<VerticalDragGestureRecognizer>(() => VerticalDragGestureRecognizer()), // Added for more robust scroll
              Factory<HorizontalDragGestureRecognizer>(() => HorizontalDragGestureRecognizer()), // Added for more robust scroll
            },
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
          // Input Form at the top, over the map
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor, // Background color for the form
              padding: const EdgeInsets.all(8.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Make column only take needed space
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectionState = LocationSelectionState.selectingStart;
                            });
                            Fluttertoast.showToast(msg: 'Tap on map to select Start Point.');
                          },
                          icon: Icon(Icons.location_on, color: Colors.green),
                          label: Text('Select Start'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _selectionState == LocationSelectionState.selectingStart ? Colors.blue.shade100 : null,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectionState = LocationSelectionState.selectingEnd;
                            });
                            Fluttertoast.showToast(msg: 'Tap on map to select End Point.');
                          },
                          icon: Icon(Icons.flag, color: Colors.red),
                          label: Text('Select End'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _selectionState == LocationSelectionState.selectingEnd ? Colors.blue.shade100 : null,
                          ),
                        ),
                      ],
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
                        minimumSize: const Size.fromHeight(50), // Make button wider
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
          // Display results if available, positioned at the bottom
          if (_predictionResult != null && !_isLoading)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Route Analysis Results:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    Text(
                        'Best Route (${_predictionResult!.vehicleType.toUpperCase()}): ${_predictionResult!.bestRoute.adjustedDurationMinutes.toStringAsFixed(2)} min'),
                    if (_predictionResult!.notBestRoute != null)
                      Text(
                          'Alternative Route: ${_predictionResult!.notBestRoute!.adjustedDurationMinutes.toStringAsFixed(2) ?? 'N/A'} min'),
                    if (_predictionResult!.weatherInfo != null)
                      Text(
                          'Weather at destination: ${_predictionResult!.weatherInfo!.description}, ${_predictionResult!.weatherInfo!.temperatureCelsius}°C'),
                    const SizedBox(height: 5),
                    const Text(
                      'Detailed Impacts (Best Route):',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    ..._predictionResult!.bestRoute.detailedImpacts.entries.map((entry) => Text('${entry.key}: ${entry.value}')).toList(),
                  ],
                ),
              ),
            ),
          if (_errorMessage != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 10, // Below app bar
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