import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:spajam_demo_app/src/models/user.dart';

class MapView extends StatefulWidget {
  static const routeName = '/map';
  const MapView({Key? key}) : super(key: key);

  @override
  State<MapView> createState() => MapViewState();
}

class MapViewState extends State<MapView> {
  late GoogleMapController _controller;
  static const CENTER_POSITION = LatLng(43.0686606, 141.3485613);
  final CameraPosition _kGooglePlex = const CameraPosition(
    target: CENTER_POSITION,
    zoom: 14,
  );
  Set<Marker> markers = {};

  Set<User> users = {};

  @override
  void initState() {
    super.initState();
    startCaptureUsers();
    startPostLocation();
    // User.fetchUsers().then((users) {
    //   setState(() {
    //     markers.addAll(users.map((e) => _userMarker(e)));
    //   });
    // });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('さがす')),
      body: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: _kGooglePlex,
        onMapCreated: (GoogleMapController controller) {
          _controller = controller;
        },
        markers: markers,
      ),
    );
  }

  Marker _userMarker(User user) {
    return Marker(
      markerId: MarkerId(user.id),
      position: LatLng(user.latitude!, user.longitude!),
    );
  }

  Timestamp? latestUpdatedAt;
  Timer? timer;
  startCaptureUsers() {
    timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      Query query = FirebaseFirestore.instance.collection('users');
      if (latestUpdatedAt != null) {
        query = query.where('updatedAt', isGreaterThan: latestUpdatedAt).orderBy('updatedAt');
      }
      query.get().then((res) async {
        // if (res.size > 0) {
        final updatedUsers = await User.fetchUsers(); // res.docs.map((e) => User.fromFirestore(e));

        latestUpdatedAt = updatedUsers.last.updatedAt;

        for (var user in updatedUsers) {
          try {
            final target = users.firstWhere((e) => e.id == user.id);
            target
              ..latitude = user.latitude
              ..longitude = user.longitude;
          } catch (e) {
            users.add(user);
          }
        }
        // }
        setState(() {
          markers = Set.from(users.where((u) => u.latitude != null).map((e) => _userMarker(e)));
        });
      });
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    timer?.cancel();
    positionTimer?.cancel();
  }

  Timer? positionTimer;
  void startPostLocation() {
    _determinePosition();

    positionTimer = Timer.periodic(Duration(seconds: 10), (timer) async {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      FirebaseFirestore.instance.collection('users').doc(auth.FirebaseAuth.instance.currentUser!.uid).update({
        'longitude': position.longitude,
        'latitude': position.latitude,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error('Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }
}
