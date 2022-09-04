import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:spajam_demo_app/src/components/common_button.dart';
import 'package:spajam_demo_app/src/components/common_label.dart';
import 'package:spajam_demo_app/src/models/user.dart';
import 'package:spajam_demo_app/src/view/image_picker_page.dart';
import 'package:spajam_demo_app/src/view/map_view.dart';
import 'dart:io';
import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:spajam_demo_app/src/register/stuff.dart';

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
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
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
  img.Image? _img;
  String? _uid;

  // アップロード処理
  void _upload() async {
    // imagePickerで画像を選択する
    var metadata = SettableMetadata(contentType: 'image/jpeg');
    Navigator.push(context, MaterialPageRoute(
      builder: (BuildContext context) {
        return ImagePickerPage(
          title: Text('新規投稿'),
          onImageSelected: (image, latlng) async {
            Navigator.pop(context);

            FirebaseStorage storage = FirebaseStorage.instance;
            AuthUser? user = auth.FirebaseAuth.instance.currentUser;
            final data = Uint8List.fromList(img.encodeJpg(image));
            try {
              await storage.ref("users/$user!.uid/profile.png").putData(data, metadata);
              setState(() {
                _img = image;
              });
            } catch (e) {
              print(e);
            }
          },
        );
      },
    ));
  }

  final _nickNameController = TextEditingController();
  final _oneLineMessageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CommonLabel(text: '写真'),
          Center(
            child: GestureDetector(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(70),
                child: _img != null
                    ? Image.memory(Uint8List.fromList(img.encodeJpg(_img!)), width: 140, fit: BoxFit.cover)
                    : Container(
                        color: Colors.grey,
                        height: 140,
                        width: 140,
                      ),
              ),
              onTap: _upload,
            ),
          ),
          Padding(padding: const EdgeInsets.all(10)),
          CommonLabel(text: 'ユーザー名'),
          TextField(
            controller: _nickNameController,
            onChanged: (nickName) {
              this.nickName = nickName;
            },
            decoration: InputDecoration(hintText: 'わらしべ太郎'),
          ),
          Padding(padding: const EdgeInsets.all(10)),
          CommonLabel(text: 'ひとこと'),
          TextField(
            controller: _oneLineMessageController,
            onChanged: (oneLineMessage) {
              this.oneLineMessage = oneLineMessage;
            },
            decoration: InputDecoration(hintText: 'ひとこと'),
          ),
          Spacer(),

          //  ビルド通ったら下を有効化
          CommonButton(
              title: '次へ',
              onPressed: () async {
                AuthUser? user = auth.FirebaseAuth.instance.currentUser;
                final userData = User(
                  id: user!.uid,
                  name: _nickNameController.text.trim(),
                  image: "/users/${user.uid}/profile.png",
                  message: _oneLineMessageController.text.trim(),
                  matchingWith: "",
                  longitude: null,
                  latitude: null,
                  itemId: "",
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
                      builder: (BuildContext context) => StuffView(),
                    ),
                  );
                } catch (e) {
                  print('-----insert error----');
                  print(e);
                }
              })
        ],
      ),
    );
  }
}
