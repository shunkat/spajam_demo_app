import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';
import 'package:spajam_demo_app/src/models/user.dart';
import 'package:spajam_demo_app/src/view/map_view.dart';
import 'dart:io';
import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

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
  Image? _img;
  String? _uid;

  // アップロード処理
  void _upload() async {
    // imagePickerで画像を選択する
    final pickerFile =
    await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickerFile == null) {
      return ;
    }
    File file = File(pickerFile.path);
    FirebaseStorage storage = FirebaseStorage.instance;
    User? user = FirebaseAuth.instance.currentUser;
    _uid = user!.uid;
    try {
      await storage.ref("$_uid/profile.png").putFile(file);
      setState(() {
        _img = Image.network("$_uid/profile.png");
      });
    } catch (e) {
      print(e);
    }
  }

  final _nickNameController = TextEditingController();
  final _oneLineMessageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        children: [
          GestureDetector(
            child: SizedBox(
              width:100,
              height:100,
              child: _img != null
                ? _img!
                : Container(
                color: Colors.grey,
              ),
            ),
            onTap: _upload,
          ),
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
                id: _uid,
                name: _nickNameController.text.trim(),
                image: "$_uid/profile.png",
                message: _oneLineMessageController.text.trim(),
                matchingWith: "",
                longitude: null,
                latitude: null,
                itemId: "",
                updatedAt: null,
              );
              try {
                var doc = FirebaseFirestore.instance.collection('users').doc(_uid);
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
