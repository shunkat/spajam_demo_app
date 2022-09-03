import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:spajam_demo_app/src/utils/firebase_utils.dart';

import '../models/test_counter.dart';

class TestCounterView extends StatefulWidget {
  const TestCounterView({Key? key}) : super(key: key);

  @override
  State<TestCounterView> createState() => TestCounterViewState();
}

class TestCounterViewState extends State<TestCounterView> {
  TestCounter? counter;
  DocumentReference<TestCounter>? counterSnapshot;

  @override
  void initState() {
    fetchCounter();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Text("${counter?.count}"),
            TextButton(onPressed: incrementFirestore, child: const Text('increment')),
          ],
        ),
      ),
    );
  }

  incrementFirestore() async {
    if (counter == null || counterSnapshot == null) return;
    await counterSnapshot!.set(counter!, SetOptions(merge: true));

    final newDoc = await counterSnapshot!.get();
    setState(() => counter = newDoc.data()!);
  }

  Future<void> fetchCounter() async {
    FirebaseFirestore.instance
        .collection('tests')
        .withConverter<TestCounter>(
          fromFirestore: (snapshot, _) => TestCounter.fromFirestore(snapshot.data()!),
          toFirestore: (data, _) => FirestoreUtils.convertForUpdating({
            ...data.toJson(),
            'count': FieldValue.increment(1),
          }),
        )
        .limit(1)
        .get()
        .then((res) async {
      if (res.size > 0) {
        counterSnapshot = res.docs[0].reference;
        setState(() {
          counter = res.docs[0].data();
        });
      } else {
        createCounter().then((res) async {
          counterSnapshot = res;
          final doc = await counterSnapshot!.get();
          if (doc.exists) {
            setState(() => counter = doc.data()!);
          }
        });
      }
    });
  }

  Future<DocumentReference<TestCounter>> createCounter() {
    TestCounter(count: 0).toJson();
    return FirebaseFirestore.instance
        .collection('tests')
        .withConverter<TestCounter>(
          fromFirestore: (snapshot, _) => TestCounter.fromFirestore(snapshot.data()!),
          toFirestore: (data, _) => FirestoreUtils.convertForUpdating(data.toJson()),
        )
        .add(counter!);
  }
}
