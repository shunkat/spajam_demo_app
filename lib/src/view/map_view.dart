import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
    User.fetchUsers().then((users) {
      setState(() {
        markers.addAll(users.map((e) => _userMarker(e)));
      });
    });
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
      position: LatLng(user.latitude, user.longitude),
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
          markers = Set.from(users.map((e) => _userMarker(e)));
        });
      });
    });
  }
}

class User {
  String id;
  String name;
  String image;
  String message;
  DocumentReference? matchingWith;
  double longitude;
  double latitude;
  DocumentReference? item;
  Timestamp? updatedAt;

  User({
    required this.id,
    required this.name,
    required this.image,
    required this.message,
    required this.matchingWith,
    required this.longitude,
    required this.latitude,
    required this.item,
    required this.updatedAt,
  });

  static Future<List<User>> fetchUsers() async {
    return [
      dummyUser(),
      dummyUser(),
      dummyUser(),
      dummyUser(),
      dummyUser(),
    ];
  }

  static User dummyUser() {
    final longitude =
        MapViewState.CENTER_POSITION.longitude + Random().nextDouble() / 10 * (Random().nextBool() ? 1 : -1);
    final latitude =
        MapViewState.CENTER_POSITION.latitude + Random().nextDouble() / 10 * (Random().nextBool() ? 1 : -1);
    return User(
      id: "$longitude-$latitude",
      name: "test",
      image: "test",
      message: "test",
      matchingWith: null,
      longitude: longitude,
      latitude: latitude,
      item: null,
      updatedAt: null,
    );
  }

  static User fromFirestore(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return User(
      id: snapshot.id,
      name: data['name'],
      image: data['image'],
      message: data['message'],
      matchingWith: data['matchingWith'],
      longitude: data['longitude'],
      latitude: data['latitude'],
      item: data['item'],
      updatedAt: data['updatedAt'],
    );
  }
}
