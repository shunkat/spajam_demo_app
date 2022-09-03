import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreUtils {
  static convertForUpdating(Map<String, dynamic> json) {
    return {
      ...json,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static convertForCreating(Map<String, dynamic> json) {
    return convertForUpdating({
      ...json,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
