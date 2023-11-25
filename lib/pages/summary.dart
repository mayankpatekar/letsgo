import 'dart:math' as Math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class SummaryPage extends StatelessWidget {
  final List<LatLng> routePoints;
  final String totalTime;

  const SummaryPage({super.key, required this.routePoints, required this.totalTime});

  @override
  Widget build(BuildContext context) {
    double totalDistance = calculateTotalDistance(routePoints);

    return Scaffold(
      appBar: AppBar(
        title: Text('Summary'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: routePoints.first,
                zoom: 15.0,
              ),
              polylines: {
                Polyline(
                  polylineId: PolylineId('route'),
                  points: routePoints,
                  color: Colors.blue,
                  width: 5,
                ),
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  'Total Time: $totalTime',
                  style: TextStyle(fontSize: 18.0),
                ),
                SizedBox(height: 10),
                Text(
                  'Total Distance: ${totalDistance.toStringAsFixed(2)} km',
                  style: TextStyle(fontSize: 18.0),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double calculateTotalDistance(List<LatLng> routePoints) {
    double totalDistance = 0.0;

    for (int i = 0; i < routePoints.length - 1; i++) {
      double distance = _calculateDistance(
        routePoints[i].latitude,
        routePoints[i].longitude,
        routePoints[i + 1].latitude,
        routePoints[i + 1].longitude,
      );
      totalDistance += distance;
    }

    return totalDistance;
  }

  double _calculateDistance(lat1, lon1, lat2, lon2) {
    const R = 6371.0; // Earth radius in kilometers

    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);

    double a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(_toRadians(lat1)) * Math.cos(_toRadians(lat2)) * Math.sin(dLon / 2) * Math.sin(dLon / 2);

    double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

    return R * c; // Distance in kilometers
  }

  double _toRadians(degrees) {
    return degrees * (Math.pi / 180);
  }
}
