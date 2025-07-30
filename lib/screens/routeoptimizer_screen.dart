// lib/screens/routeoptimizer_screen.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/gestures.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/models.dart';
import '../services/api_services.dart'; // Ensure this import is correct

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


  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(12.9716, 77.5946), // Bangalore, India
    zoom: 12.0,
  );

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  @override
  void dispose() {
    _googleMapController?.dispose();
    _histStartYearController.dispose();
    _histEndYearController.dispose();
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

  void _onMapTap(LatLng tappedLatLng) async {
    if (_selectionState == LocationSelectionState.selectingStart) {
      setState(() {
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
      setState(() {
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
      if (_googleMapController != null) {
        final double currentZoom = await _googleMapController!.getZoomLevel();
        setState(() {
          _googleMapController!.animateCamera(
            CameraUpdate.newLatLngZoom(tappedLatLng, currentZoom),
          );
        });
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

      setState(() {
        _startLatLng = currentLatLng;
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
        context: context, // Pass context here
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

        // Draw all routes
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

        // Add current accidents markers
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

        // Add historical accidents markers
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
    // Also consider accident locations for fitting bounds
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

    // Add some padding to the bounds
    _googleMapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50.0), // 50.0 is padding
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
              color: Theme.of(context).scaffoldBackgroundColor,
              padding: const EdgeInsets.all(8.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                          icon: const Icon(Icons.location_on, color: Colors.green),
                          label: const Text('Select Start'),
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
                          icon: const Icon(Icons.flag, color: Colors.red),
                          label: const Text('Select End'),
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
                    // --- Best Route Details ---
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

                    // --- Not Best Route Details (if available) ---
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

                    // --- All Data Details (Scrollable) ---
                    const SizedBox(height: 16),
                    Text(
                      'Comprehensive Analysis:',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.4, // Adjust height as needed
                      child: ListView(
                        children: [
                          // Weather Info Card
                          if (_predictionResult!.weatherInfo != null)
                            Card(
                              margin: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Weather Information:',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    const Divider(),
                                    Text('Description: ${_predictionResult!.weatherInfo!.description ?? 'N/A'}'),
                                    Text('Temperature: ${_predictionResult!.weatherInfo!.temperatureCelsius?.toStringAsFixed(1) ?? 'N/A'}°C'),
                                    Text('Humidity: ${_predictionResult!.weatherInfo!.humidityPercent?.toString() ?? 'N/A'}%'),
                                    Text('Wind Speed: ${_predictionResult!.weatherInfo!.windSpeedMps?.toStringAsFixed(1) ?? 'N/A'} m/s'),
                                    Text('Visibility: ${_predictionResult!.weatherInfo!.visibilityMeters?.toString() ?? 'N/A'} meters'),
                                    Text('Category: ${_predictionResult!.weatherInfo!.category ?? 'N/A'}'),
                                  ],
                                ),
                              ),
                            ),

                          // Current Accidents Card
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
                                    ..._predictionResult!.simulatedCurrentAccidents.map((accident) => Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Type: ${accident.type ?? 'N/A'} (Severity: ${accident.severity ?? 'N/A'})'),
                                          Text('Location: ${accident.latitude?.toStringAsFixed(4) ?? 'N/A'}, ${accident.longitude?.toStringAsFixed(4) ?? 'N/A'}'),
                                          Text('Delay: ${accident.simulatedDelayMinutes?.toStringAsFixed(1) ?? 'N/A'} min'),
                                          Text('Description: ${accident.description ?? 'N/A'}'),
                                          const SizedBox(height: 8),
                                        ],
                                      ),
                                    )).toList(),
                                  ],
                                ),
                              ),
                            ),

                          // Historical Accidents Card
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
                                    ..._predictionResult!.simulatedHistoricalAccidents.map((accident) => Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                                      child: Column(
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
                                      ),
                                    )).toList(),
                                  ],
                                ),
                              ),
                            ),

                          // All Routes Details (Optional - only if more than 2 routes to list beyond best/not-best)
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
                    ),
                  ],
                ),
              ),
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