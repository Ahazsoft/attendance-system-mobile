import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class GeoCheckPage extends StatefulWidget {
  const GeoCheckPage({super.key});

  @override
  State<GeoCheckPage> createState() => _GeoCheckPageState();
}

class _GeoCheckPageState extends State<GeoCheckPage> {
  // 8.986054854174442, 38.78798197585552
  // static const double centerLat = 9.018535962041083;
  // static const double centerLng = 38.8112968601194;
  static const double centerLat = 8.986054854174442;
  static const double centerLng = 38.78798197585552;
  static const double allowedRadius = 50;

  Future<bool> checkLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return false;
    }

    // New LocationSettings API
    LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high, // accuracy for all platforms
      distanceFilter: 0,
    );

    Position position = await Geolocator.getCurrentPosition(
      locationSettings: locationSettings,
    );

    double distance = Geolocator.distanceBetween(
      centerLat,
      centerLng,
      position.latitude,
      position.longitude,
    );

    if (distance <= allowedRadius) {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(
      //     content: Text("You are inside the allowed area"),
      //     duration: Duration(seconds: 20),
      //   ),
      // );
      return true;
    } else {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text(
      //       "You are ${distance.toStringAsFixed(2)} meters away from the location",
      //     ),
      //   ),
      // );
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    checkLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Geofence Check")),
      body: SafeArea(
        child: Center(
          child: ElevatedButton(
            onPressed: checkLocation,
            child: const Text("Check Location"),
          ),
        ),
      ),
    );
  }
}
