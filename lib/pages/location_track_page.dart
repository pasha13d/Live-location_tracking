import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:live_location_track/constants.dart';
import 'package:location/location.dart';

class LocationTrackPage extends StatefulWidget {
  const LocationTrackPage({Key? key}) : super(key: key);

  @override
  State<LocationTrackPage> createState() => _LocationTrackPageState();
}

class _LocationTrackPageState extends State<LocationTrackPage> {
  final Completer<GoogleMapController> _controller = Completer();
  static const LatLng sourceLocation = LatLng(37.42231261326982, -122.08410044823147);
  static const LatLng destLocation = LatLng(37.411797759707696, -122.07135561762125);

  List<LatLng> polylineCoordinates = [];
  LocationData? currentLocation;

  void getCurrentLocation() async {
    Location location = Location();

    location.getLocation().then(
      (location) {
        currentLocation = location;
      },
    );

    GoogleMapController googleMapController = await _controller.future;

    location.onLocationChanged.listen((newLocation) {
      currentLocation = newLocation;
      /// animate camera to a new position
      googleMapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            zoom: 13.5,
            target: LatLng(
              newLocation.latitude!,
              newLocation.longitude!,
            ),
          )
        )
      );
      setState(() {});
    });
  }

  /// draw polyline
  void getPolyPoints() async {
    PolylinePoints polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        Constants.google_api_key,
        PointLatLng(sourceLocation.latitude, sourceLocation.longitude),
        PointLatLng(destLocation.latitude, destLocation.longitude),
    );
    if(result.points.isNotEmpty) {
      result.points.forEach(
          (PointLatLng point) => polylineCoordinates.add(
            LatLng(point.latitude, point.longitude),
          ),
      );
      setState(() {});
    }
  }

  @override
  void initState() {
    getCurrentLocation();
    getPolyPoints();
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Live Location Track',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
          ),
        ),
      ),
      body: currentLocation == null
        ? Center(child: CircularProgressIndicator())
        : GoogleMap(
          /// initial camera position
          initialCameraPosition: CameraPosition(
            target: LatLng(
              currentLocation!.latitude!,
              currentLocation!.longitude!,
            ),
            zoom: 13.5
          ),
          /// show polyline
          polylines: {
            Polyline(
              polylineId: const PolylineId('route'),
              points: polylineCoordinates,
              color: Constants.primaryColor,
              width: 6,
            ),
          },
          /// show marker
          markers: {
            Marker(
              markerId: const MarkerId('currentLocation'),
              position: LatLng(
                currentLocation!.latitude!,
                currentLocation!.longitude!,
              ),
            ),
            const Marker(
              markerId: MarkerId('source'),
              position: sourceLocation,
            ),
            const Marker(
              markerId: MarkerId('destination'),
              position: destLocation,
            ),
          },
        onMapCreated: (mapController) {
            _controller.complete(mapController);
        },
        ),
    );
  }
}
