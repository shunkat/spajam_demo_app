import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../models/test_counter.dart';

class TestCounterView extends StatefulWidget {
  const TestCounterView({Key? key}) : super(key: key);

  @override
  State<TestCounterView> createState() => TestCounterViewState();
}

class TestCounterViewState extends State<TestCounterView> {
  TestCounter? counter;
  DocumentReference<Map<String, dynamic>>? counterSnapshot;

  @override
  void initState() {
    fetchCounter();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Text("${counter?.count}"),
          TextButton(onPressed: incrementFirestore, child: const Text('increment')),
        ],
      ),
    );
  }

  incrementFirestore() async {
    if (counter == null || counterSnapshot == null) return;
    await counterSnapshot!.set({
      'count': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final newDoc = await counterSnapshot!.get();
    setState(() {
      counter = TestCounter.fromFirestore(newDoc.data()!);
    });
  }

  Future<void> fetchCounter() async {
    FirebaseFirestore.instance.collection('tests').limit(1).get().then((res) async {
      if (res.size > 0) {
        counterSnapshot = res.docs[0].reference;
        setState(() {
          counter = TestCounter.fromFirestore(res.docs[0].data());
        });
      } else {
        createCounter().then((res) async {
          counterSnapshot = res;
          final doc = await res.get();
          if (doc.exists) {
            setState(() {
              counter = TestCounter.fromFirestore(doc.data()!);
            });
          }
        });
      }
    });
  }

  Future<DocumentReference<Map<String, dynamic>>> createCounter() {
    TestCounter(count: 0).toFirestore();
    return FirebaseFirestore.instance.collection('tests').add({
      ...TestCounter(count: 0).toFirestore(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
