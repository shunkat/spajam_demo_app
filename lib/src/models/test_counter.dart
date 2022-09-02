import 'package:cloud_firestore/cloud_firestore.dart';

class TestCounter {
  int count = 0;
  DateTime? updatedAt;
  DateTime? createdAt;

  TestCounter({required this.count, this.updatedAt, this.createdAt});

  Map<String, dynamic> toFirestore() {
    return {
      'count': count,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static TestCounter fromFirestore(Map<String, dynamic> data) {
    return TestCounter(
      count: data['count'],
      updatedAt: data['updatedAt'] == null ? DateTime.now() : data['updatedAt'].toDate(),
      createdAt: data['createdAt'] == null ? DateTime.now() : data['createdAt'].toDate(),
    );
  }
}
