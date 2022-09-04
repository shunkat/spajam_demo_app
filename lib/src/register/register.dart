import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spajam_demo_app/src/components/common_button.dart';

import '../components/common_label.dart';
import '../register/profile.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(RegisterView());
}

class RegisterView extends StatelessWidget {
  const RegisterView({Key? key}) : super(key: key);

  static const routeName = '/register';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('新規登録'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
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

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CommonLabel(text: 'Eメール'),
          TextField(
            controller: _emailController,
            onChanged: (email) {
              this.email = email;
            },
            decoration: InputDecoration(hintText: 'email@example.com'),
          ),
          Padding(padding: EdgeInsets.all(10)),
          CommonLabel(text: 'パスワード'),
          TextField(
            controller: _passwordController,
            onChanged: (password) {
              this.password = password;
            },
            obscureText: true,
            decoration: InputDecoration(hintText: 'password'),
          ),

          //  ビルド通ったら下を有効化
          Spacer(),
          CommonButton(
            title: '次へ',
            onPressed: () async {
              try {
                final FirebaseAuth auth = FirebaseAuth.instance;
                final UserCredential result = await auth.createUserWithEmailAndPassword(
                  email: _emailController.text.trim(),
                  password: _passwordController.text.trim(),
                );

                final User user = result.user!;

                final snackBar = SnackBar(
                  content: Text(user.email!),
                );

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileView(),
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
