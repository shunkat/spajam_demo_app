import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../view/map_view.dart';

class User {
  String id;
  String name;
  String? image;
  String message;
  String matchingWith = "";
  double? longitude;
  double? latitude;
  String itemId = "";
  Timestamp? updatedAt;
  bool isApproved = false;

  User({
    required this.id,
    required this.name,
    this.image,
    required this.message,
    this.matchingWith = "",
    this.longitude,
    this.latitude,
    this.itemId = "",
    this.updatedAt,
    this.isApproved = false,
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
      matchingWith: "",
      longitude: longitude,
      latitude: latitude,
      itemId: "",
      updatedAt: null,
    );
  }

  static User fromFirestore(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return User(
      id: data['id'],
      name: data['name'],
      image: data['image'],
      message: data['message'],
      matchingWith: data['matchingWith'],
      longitude: data['longitude'],
      latitude: data['latitude'],
      itemId: data['itemId'],
      updatedAt: data['updatedAt'],
    );
  }

  static Map<String, dynamic> toFirestore(User user) {
    return {
      'id': user.id,
      'name': user.name,
      'image': user.image,
      'message': user.message,
      'matchingWith': user.matchingWith,
      'longitude': user.longitude,
      'latitude': user.latitude,
      'itemId': user.itemId,
      'isApproved': user.isApproved,
      'updatedAt': user.updatedAt,
    };
  }
}
