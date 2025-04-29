import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapPickerScreen extends StatefulWidget {
  @override
  _MapPickerScreenState createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  LatLng? selectedLocation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Location'),
        backgroundColor: Colors.green,
        actions: [
          TextButton(
            onPressed: () {
              if (selectedLocation != null) {
                Navigator.pop(context, selectedLocation);
              } else {
                Navigator.pop(context, null);
              }
            },
            child: const Text('Done', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: LatLng(14.5995, 120.9842), // default to Manila
          zoom: 14,
        ),
        onTap: (LatLng latLng) {
          setState(() {
            selectedLocation = latLng;
          });
        },
        markers: selectedLocation == null
            ? {}
            : {
                Marker(
                  markerId: const MarkerId('selected-location'),
                  position: selectedLocation!,
                ),
              },
      ),
    );
  }
}