import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapView extends StatefulWidget {
  static const routeName = '/map';
  const MapView({Key? key}) : super(key: key);

  @override
  State<MapView> createState() => MapViewState();
}

class MapViewState extends State<MapView> {
  late GoogleMapController _controller;
  //初期位置
  final CameraPosition _kGooglePlex = const CameraPosition(
    target: LatLng(43.0686606, 141.3485613),
    zoom: 14,
  );
  Set<Marker> markers = {};

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
        markers: {
          userMarker(User.dummyUser(141.3485613, 43.0686606)),
          userMarker(User.dummyUser(141.1222, 43.06231)),
        },
      ),
    );
  }

  Marker userMarker(User user) {
    return Marker(
      markerId: MarkerId(user.id),
      position: LatLng(user.latitude, user.longitude),
    );
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

  User({
    required this.id,
    required this.name,
    required this.image,
    required this.message,
    required this.matchingWith,
    required this.longitude,
    required this.latitude,
    required this.item,
  });

  static User dummyUser(double longitude, double latitude) {
    return User(
      id: "$longitude-$latitude",
      name: "test",
      image: "test",
      message: "test",
      matchingWith: null,
      longitude: longitude,
      latitude: latitude,
      item: null,
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
    );
  }
}
