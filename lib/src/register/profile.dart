import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../sample_feature/sample_item_list_view.dart';

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
              User? user = FirebaseAuth.instance.currentUser;
              Map<String, dynamic> insertObj = {
                'id': user!.uid,
                'name': _nickNameController.text.trim(),
                'message': _oneLineMessageController.text.trim(),
              };
              try {
                var doc = await FirebaseFirestore.instance.collection('users').doc(user.uid);
                await doc.set(insertObj);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                  builder: (BuildContext context) => SampleItemListView(),
                ),);
              } catch ( e ) {
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