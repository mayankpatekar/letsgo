import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:letsgo/pages/summary.dart';
import 'package:permission_handler/permission_handler.dart';


class MyMapPage extends StatefulWidget {
@override
_MyMapPageState createState() => _MyMapPageState();
}

class _MyMapPageState extends State<MyMapPage> {
  late GoogleMapController mapController;
  late BitmapDescriptor customMarkerIcon;
  Set<Marker> markers = {};
  DateTime? startTime;
  Set<Polyline> polylines = {};
  bool isCyclingStarted = false;
  late Timer timer = Timer(Duration.zero, () => {});
  bool isPaused = false;
  int elapsedSeconds = 0; // Track elapsed seconds when paused
  List<LatLng> recordedPositions = [];

  late Position? currentPosition = Position(
    latitude: 0.0,
    longitude: 0.0,
    altitude: 0.0,
    accuracy: 0.0,
    heading: 0.0,
    speed: 0.0,
    speedAccuracy: 0.0,
    timestamp: DateTime.now(),
    altitudeAccuracy: 0.0,
    headingAccuracy: 0.0,
  );

  @override
  void initState() {
    super.initState();
    currentPosition = null; // Initialize currentPosition as null
    _requestLocationPermission();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Letsgo'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (GoogleMapController controller) async {
              setState(() {
                mapController = controller;
              });
              Future.delayed(Duration(milliseconds: 10), () {
                _getCurrentLocation();
              });
            },
            initialCameraPosition: CameraPosition(
              target: LatLng(
                currentPosition?.latitude ?? 0.0,
                currentPosition?.longitude ?? 0.0,
              ),
              zoom: 17.0,
            ),
            markers: markers,
            polylines: polylines,
          ),
          Positioned(
            top: 16.0,
            left: 16.0,
            right: 16.0,
            child: isCyclingStarted
                ? Text(
              'Time: ${_formattedElapsedTime()}',
              style: TextStyle(fontSize: 18.0),
            )
                : Text(
              isCyclingStarted ? 'Cycling in Progress' : 'Start Cycling',
              style: TextStyle(fontSize: 18.0),
            ),
          ),
          Positioned(
            bottom: 16.0,
            left: 16.0,
            right: 16.0,
            child: isCyclingStarted
                ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: isPaused ? resumeCycling : pauseCycling,
                  child: Text(isPaused ? 'Resume' : 'Pause'),
                ),
                ElevatedButton(
                  onPressed: finishCycling,
                  child: Text('Finish'),
                ),
              ],
            )
                : ElevatedButton(
              onPressed: isCyclingStarted ? null : startCycling,
              child: Text(
                isCyclingStarted ? 'Cycling in Progress' : 'Start Cycling',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _requestLocationPermission() async {
    var status = await Permission.location.status;
    if (status == PermissionStatus.granted) {
      _getCurrentLocation();
    } else {
      // Request location permissions
      var result = await Permission.location.request();
      if (result == PermissionStatus.granted) {
        _getCurrentLocation();
      } else {
        // Handle the case where the user denies location permissions
        print('Location permissions are denied');
      }
    }
  }

  String _formattedElapsedTime() {
    if (startTime == null) {
      return '00:00:00';
    }

    Duration elapsed;

    if (isPaused) {
      elapsed = Duration(seconds: elapsedSeconds);
    } else {
      elapsed = DateTime.now().difference(startTime!);
      elapsedSeconds = elapsed.inSeconds; // Save elapsed seconds when paused
    }

    int hours = elapsed.inHours;
    int minutes = (elapsed.inMinutes % 60);
    int seconds = (elapsed.inSeconds % 60);

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _getCurrentLocation() async {
    var status = await Permission.location.status;
    if (status == PermissionStatus.granted) {
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        setState(() {
          currentPosition = position;
        });

        // Clear existing markers and add a new one for the current location
        markers.clear();
        customMarkerIcon = await BitmapDescriptor.fromAssetImage(
          const ImageConfiguration(),
          'assets/images/marker.png',
        );
        markers.add(
          Marker(
            markerId: MarkerId('user_location'),
            position: LatLng(position.latitude, position.longitude),
            icon: customMarkerIcon,
            infoWindow: InfoWindow(title: 'Your Location'),
          ),
        );

        if (mapController != null) {
          mapController.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(position.latitude, position.longitude),
              17.0, // Adjust the zoom level as needed
            ),
          );
        }

        print('Latitude: ${position.latitude}, Longitude: ${position.longitude}');
      } catch (e) {
        print('Error getting location: $e');
      }
    } else {
      // Handle the case where the user denies location permissions
      print('Location permissions are denied');
    }
  }

  void simulateLocationUpdates() {
    Timer.periodic(Duration(seconds: 1), (Timer timer) async {
      if (!isCyclingStarted) {
        // Stop location updates if cycling is stopped
        timer.cancel();
      } else {
        try {
          Position newPosition = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );

          setState(() {
            recordedPositions.add(LatLng(newPosition.latitude, newPosition.longitude));

            polylines.clear();
            polylines.add(Polyline(
              polylineId: PolylineId('route'),
              points: List.from(recordedPositions),
              color: Colors.red,
              width: 5,
            ));

            markers.clear();
            markers.add(
              Marker(
                markerId: MarkerId('user_location'),
                position: LatLng(newPosition.latitude, newPosition.longitude),
                icon: customMarkerIcon,
                infoWindow: InfoWindow(title: 'Your Location'),
              ),
            );
          });

          mapController.animateCamera(
            CameraUpdate.newLatLng(LatLng(newPosition.latitude, newPosition.longitude)),
          );
        } catch (e) {
          print('Error getting location: $e');
        }
      }
    });
  }

  void startCycling() {
    setState(() {
      isCyclingStarted = true;
      startTime = DateTime.now();
      polylines.clear();
      markers.clear(); // Clear markers to ensure a fresh start
    });

    _getCurrentLocation(); // Fetch and set the initial location

    timer = Timer.periodic(Duration(seconds: 1), (Timer timer) {
      simulateLocationUpdates();
    });
  }


  void pauseCycling() {
    setState(() {
      isPaused = true;
      timer.cancel();
    });
  }

  void resumeCycling() {
    setState(() {
      isPaused = false;
      // Restart the timer with the remaining time
      timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
        simulateLocationUpdates();
      });
    });
  }

  void finishCycling() {
    if (isCyclingStarted) {
      isCyclingStarted = false;
      // Stop location updates when cycling is finished
      timer.cancel();

      // Get the current location as the ending point
      Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
          .then((endingPosition) async {
        if (endingPosition != null) {
          // Draw the final polyline using all recorded positions
          polylines.add(Polyline(
            polylineId: PolylineId('final_route'),
            points: List.from(recordedPositions),
            color: Colors.blue,
            width: 5,
          ));

          // Update the markers to show the ending position
          markers.clear();
          customMarkerIcon = await BitmapDescriptor.fromAssetImage(
            const ImageConfiguration(),
            'assets/images/marker.png',
          );
          markers.add(
            Marker(
              markerId: MarkerId('user_location'),
              position: LatLng(endingPosition.latitude, endingPosition.longitude),
              icon: customMarkerIcon,
              infoWindow: InfoWindow(title: 'Your Location'),
            ),
          );

          // Center the map on the ending position
          mapController.animateCamera(
            CameraUpdate.newLatLng(
              LatLng(endingPosition.latitude, endingPosition.longitude),
            ),
          );


          // Navigate to the summary page
          // ignore: use_build_context_synchronously
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SummaryPage(
                routePoints: List.from(recordedPositions),
                totalTime: _formattedElapsedTime(),
              ),
            ),
          );
          setState(() {
            // Clear existing markers
            // markers.clear();
            polylines.clear();
          });
        }
      });
    }
  }



  @override
  void dispose() {
    print('Disposing...');
    if (timer != null && timer.isActive) {
      timer.cancel();
      print('Timer canceled.');
    }
    super.dispose();
  }
}
