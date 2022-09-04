import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:spajam_demo_app/src/components/common_button.dart';
import 'package:spajam_demo_app/src/components/common_label.dart';
import 'package:spajam_demo_app/src/register/profile.dart';
import 'package:spajam_demo_app/src/view/map_view.dart';

import '../sample_feature/sample_item_list_view.dart';
import '../view/image_picker_page.dart';

class StuffView extends StatelessWidget {
  const StuffView({Key? key}) : super(key: key);

  static const routeName = '/stuff';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('物品登録'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
        ),
        body: MyStuffView(),
      ),
    );
  }
}

class MyStuffView extends StatefulWidget {
  const MyStuffView({Key? key}) : super(key: key);

  @override
  State<MyStuffView> createState() => _MyStuffViewState();
}

class _MyStuffViewState extends State<MyStuffView> {
  String? name;
  String? detail;
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
              await storage.ref("items/${user!.uid}/stuff.png").putData(data, metadata);
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

  final _nameController = TextEditingController();
  final _detailController = TextEditingController();

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
          CommonLabel(text: '物品名'),
          TextField(
            controller: _nameController,
            onChanged: (name) {
              this.name = name;
            },
            decoration: InputDecoration(hintText: '物品名'),
          ),
          Padding(padding: const EdgeInsets.all(10)),
          CommonLabel(text: 'ひとこと'),
          TextField(
            controller: _detailController,
            onChanged: (detail) {
              this.detail = detail;
            },
            decoration: InputDecoration(hintText: 'ひとこと'),
          ),
          Spacer(),
          //  ビルド通ったら下を有効化
          CommonButton(
            title: '登録',
            onPressed: () async {
              AuthUser? user = auth.FirebaseAuth.instance.currentUser;
              Map<String, dynamic> insertObj = {
                'name': _nameController.text.trim(),
                'detail': _detailController.text.trim(),
                'image': "items/${user!.uid}/stuff.png"
              };
              try {
                await FirebaseFirestore.instance.collection("items").doc(user.uid).set(insertObj);

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (BuildContext context) => MapView(),
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
