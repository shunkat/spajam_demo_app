import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../sample_feature/sample_item_list_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(RegisterView());
}

class RegisterView extends StatelessWidget {
  const RegisterView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('新規登録/ログイン画面'),
        ),
        body: MyRegisterView(),
      ),
    );
  }
}

class MyRegisterView extends StatefulWidget {
  const MyRegisterView({Key? key}) : super(key: key);

  @override
  State<MyRegisterView> createState() => _MyRegisterViewState();
}

class _MyRegisterViewState extends State<MyRegisterView> {
  String? email;
  String? password;
  String? tweet;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _tweetController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        children: [
          TextField(
            controller: _emailController,
            onChanged: (email) {
              this.email = email;
            },
            decoration: InputDecoration(hintText: 'Eメール'),
          ),
          TextField(
            controller: _passwordController,
            onChanged: (password) {
              this.password = password;
            },
            obscureText: true,
            decoration: InputDecoration(hintText: 'パスワード'),
          ),

          TextField(
            controller: _tweetController,
            onChanged: (password) {
              this.tweet = tweet;
            },
            decoration: InputDecoration(hintText: 'あなたを表す一言'),
          ),

          //  ビルド通ったら下を有効化
          ElevatedButton(
            child: Text('登録/ログイン'),
            onPressed: () async {
              try {
                await FirebaseAuth.instance.signInWithEmailAndPassword(
                  email: _emailController.text.trim(),
                  password: _passwordController.text.trim(),
                );
                final user = FirebaseAuth.instance.currentUser!;

                final snackBar = SnackBar(
                  content: Text(user.email!),
                );

                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (BuildContext context) => SampleItemListView(),
                    ),
                );
              } catch (e) {
                print(e);
              }
            },
          )
        ],
      ),
    );
  }
}