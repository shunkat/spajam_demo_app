import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  late BitmapDescriptor matchingIcon;
  late BitmapDescriptor normalIcon;
  static const CENTER_POSITION = LatLng(43.0686606, 141.3485613);
  final CameraPosition _kGooglePlex = const CameraPosition(
    target: CENTER_POSITION,
    zoom: 14,
  );
  CameraPosition? _initialPosition;
  Set<Marker> markers = {};

  Set<User> users = {};

  @override
  void initState() {
    super.initState();
    setInitialPosition();
    startCaptureUsers();
    startPostLocation();
    prepareIcons();
  }

  prepareIcons() {
    imageChangeUint8List('assets/images/marker.png', 104, 92).then((onValue) {
      normalIcon = BitmapDescriptor.fromBytes(onValue);
    });
    imageChangeUint8List('assets/images/matching_marker.png', 104, 92).then((onValue) {
      matchingIcon = BitmapDescriptor.fromBytes(onValue);
    });
  }

  Future<Uint8List> imageChangeUint8List(String path, int height, int width) async {
    final ByteData byteData = await rootBundle.load(path);
    final Codec codec = await instantiateImageCodec(
      byteData.buffer.asUint8List(),
      targetHeight: height,
      targetWidth: width,
    );
    final FrameInfo uiFI = await codec.getNextFrame();
    return (await uiFI.image.toByteData(format: ImageByteFormat.png))!.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('さがす')),
      body: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: _initialPosition ?? _kGooglePlex,
        onMapCreated: (GoogleMapController controller) {
          _controller = controller;
        },
        markers: markers,
        myLocationEnabled: true,
      ),
    );
  }

  Marker _userMarker(User user) {
    return Marker(
      markerId: MarkerId(user.id),
      icon: user.matchingWith == null ? normalIcon : matchingIcon,
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
        if (res.size > 0) {
          final updatedUsers = res.docs.map((e) => User.fromFirestore(e));

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
        }
        setState(() {
          markers = Set.from(users.where((u) {
            return u.id != auth.FirebaseAuth.instance.currentUser!.uid && u.latitude != null;
          }).map((e) => _userMarker(e)));
        });
      });
    });
  }

  @override
  void dispose() {
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

  void setInitialPosition() async {
    await _determinePosition();
    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _initialPosition = CameraPosition(target: LatLng(position.latitude, position.longitude), zoom: 14);
    });
  }
}
