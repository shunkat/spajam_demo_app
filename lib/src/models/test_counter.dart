import 'package:cloud_firestore/cloud_firestore.dart';

class TestCounter {
  int count = 0;
  DateTime? updatedAt;
  DateTime? createdAt;

  bool incrementCounter = false;

  TestCounter({required this.count, this.updatedAt, this.createdAt});

  Map<String, dynamic> toJson() {
    return {
      'count': incrementCounter ? FieldValue.serverTimestamp() : count,
      'updatedAt': updatedAt,
      'createdAt': createdAt,
    };
  }

  static TestCounter fromFirestore(Map<String, dynamic> data) {
    return TestCounter(
      count: data['count'],
      updatedAt: data['updatedAt']?.toDate(),
      createdAt: data['createdAt']?.toDate(),
    );
  }
}
