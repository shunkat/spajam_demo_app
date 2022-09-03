import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';
import 'package:spajam_demo_app/src/models/user.dart';
import 'package:spajam_demo_app/src/view/map_view.dart';

import '../sample_feature/sample_item_list_view.dart';

typedef AuthUser = auth.User;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(ProfileView());
}

class ProfileView extends StatelessWidget {
  const ProfileView({Key? key}) : super(key: key);

  static const routeName = '/profile';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('プロフィール作成'),
        ),
        body: MyProfileView(),
      ),
    );
  }
}

class MyProfileView extends StatefulWidget {
  const MyProfileView({Key? key}) : super(key: key);

  @override
  State<MyProfileView> createState() => _MyProfileViewState();
}

class _MyProfileViewState extends State<MyProfileView> {
  String? nickName;
  String? oneLineMessage;

  final _nickNameController = TextEditingController();
  final _oneLineMessageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        children: [
          TextField(
            controller: _nickNameController,
            onChanged: (nickName) {
              this.nickName = nickName;
            },
            decoration: InputDecoration(hintText: 'ユーザー名'),
          ),
          TextField(
            controller: _oneLineMessageController,
            onChanged: (oneLineMessage) {
              this.oneLineMessage = oneLineMessage;
            },
            decoration: InputDecoration(hintText: 'ひとこと'),
          ),

          //  ビルド通ったら下を有効化
          ElevatedButton(
            child: Text('次へ'),
            onPressed: () async {
              AuthUser? user = auth.FirebaseAuth.instance.currentUser;
              final userData = User(
                id: user!.uid,
                name: _nickNameController.text.trim(),
                image: null,
                message: _oneLineMessageController.text.trim(),
                matchingWith: null,
                longitude: null,
                latitude: null,
                itemRef: null,
                updatedAt: null,
              );
              try {
                var doc = FirebaseFirestore.instance.collection('users').doc(user.uid);
                await doc.set({
                  ...User.toFirestore(userData),
                  'updatedAt': FieldValue.serverTimestamp(),
                });

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (BuildContext context) => SampleItemListView(),
                  ),
                );
              } catch (e) {
                print('-----insert error----');
                print(e);
              }
            },
          )
        ],
      ),
    );
  }
}
