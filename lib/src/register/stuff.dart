import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../sample_feature/sample_item_list_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(StuffView());
}

class StuffView extends StatelessWidget {
  const StuffView({Key? key}) : super(key: key);

  static const routeName = '/stuff';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('物品登録'),
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
      await storage.ref("items/$_uid/stuff.png").putFile(file);
      setState(() {
        _img = Image.network("items/$_uid/stuff.png");
      });
    } catch (e) {
      print(e);
    }
  }

  final _nameController = TextEditingController();
  final _detailController = TextEditingController();

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
            controller: _nameController,
            onChanged: (name) {
              this.name = name;
            },
            decoration: InputDecoration(hintText: '物品名'),
          ),
          TextField(
            controller: _detailController,
            onChanged: (detail) {
              this.detail = detail;
            },
            decoration: InputDecoration(hintText: 'ひとこと'),
          ),

          //  ビルド通ったら下を有効化
          ElevatedButton(
            child: Text('次へ'),
            onPressed: () async {
              User? user = FirebaseAuth.instance.currentUser;
              Map<String, dynamic> insertObj = {
                'name': _nameController.text.trim(),
                'detail': _detailController.text.trim(),
                'image': "items/$_uid/stuff.png"
              };
              try {
                await FirebaseFirestore.instance.collection("items").doc(_uid).set(insertObj);

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
