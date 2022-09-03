import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:spajam_demo_app/src/models/test_counter.dart';

class TestCounterRepository {
  final _db = FirebaseFirestore.instance;
  late final _ref = _db.collection('tests');

  Future<TestCounter?> getTestCounter() async {
    final res = await _ref.limit(1).get();
    if (res.size > 0) {
      TestCounter.fromFirestore(res.docs[0].data());
    }
  }

  Future<bool> setTestCounter(String id, TestCounter counter) async {
    _ref.doc(id).set(counter.toJson());
  }
}
