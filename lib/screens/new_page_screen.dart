// lib/screens/new_page_screen.dart

import 'package:flutter/material.dart';
import 'package:optiroute/services/api_services.dart'; // Import ApiService
import 'package:optiroute/models/models.dart'; // Import models (which now exports ReportedAccident)
import 'package:optiroute/constants/strings.dart'; // For BASE_URL
import 'package:optiroute/screens/image_view_screen.dart';

import '../models/reported_accident.dart' show ReportedAccident; // Import the new image viewer screen

class NewPageScreen extends StatefulWidget {
  const NewPageScreen({super.key});

  @override
  State<NewPageScreen> createState() => _NewPageScreenState();
}

class _NewPageScreenState extends State<NewPageScreen> {
  late Future<List<ReportedAccident>> _reportedAccidentsFuture;

  @override
  void initState() {
    super.initState();
    _reportedAccidentsFuture = ApiService.getCurrentUserReportedAccidents(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reported Incidents'),
        backgroundColor: Colors.teal,
      ),
      body: FutureBuilder<List<ReportedAccident>>(
        future: _reportedAccidentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 60),
                    const SizedBox(height: 10),
                    Text(
                      'Error loading reports: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _reportedAccidentsFuture = ApiService.getCurrentUserReportedAccidents(context);
                        });
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No incidents reported by you yet.',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context); // Go back to the previous screen
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Go Back'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      textStyle: const TextStyle(fontSize: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            );
          } else {
            // Display the list of reported accidents
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final report = snapshot.data![index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16.0),
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Incident Type: ${report.incidentType}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Description: ${report.description ?? 'N/A'}',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Status: ${report.status}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: report.status == 'resolved' ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Reported At: ${report.reportedAt.substring(0, 10)}', // Display date only
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          'Location: ${report.latitude.toStringAsFixed(4)}, ${report.longitude.toStringAsFixed(4)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 16),
                        if (report.mediaPaths.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Uploaded Media:',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 150, // Fixed height for media display
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: report.mediaPaths.length,
                                  itemBuilder: (context, mediaIndex) {
                                    final mediaPath = report.mediaPaths[mediaIndex];
                                    final mediaUrl = ApiService.getMediaFileUrl(mediaPath);
                                    final isImage = mediaPath.toLowerCase().endsWith('.jpg') ||
                                        mediaPath.toLowerCase().endsWith('.jpeg') ||
                                        mediaPath.toLowerCase().endsWith('.png');
                                    final isVideo = mediaPath.toLowerCase().endsWith('.mp4') ||
                                        mediaPath.toLowerCase().endsWith('.mov');

                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8.0),
                                      child: InkWell( // Make the media tappable
                                        onTap: isImage // Only allow tap for images for now
                                            ? () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => ImageViewScreen(imageUrl: mediaUrl),
                                            ),
                                          );
                                        }
                                            : null, // Disable tap for videos/other for now
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8.0),
                                          child: isImage
                                              ? Image.network(
                                            mediaUrl,
                                            width: 150,
                                            height: 150,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                width: 150,
                                                height: 150,
                                                color: Colors.grey[300],
                                                child: Icon(Icons.broken_image, color: Colors.grey[600]),
                                              );
                                            },
                                          )
                                              : isVideo
                                              ? Container(
                                            width: 150,
                                            height: 150,
                                            color: Colors.black,
                                            child: const Center(
                                              child: Icon(Icons.video_collection, color: Colors.white, size: 50),
                                            ),
                                          )
                                              : Container(
                                            width: 150,
                                            height: 150,
                                            color: Colors.grey[300],
                                            child: Icon(Icons.insert_drive_file, color: Colors.grey[600]),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
