import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:omnifit_front/constants/assets.dart';
import 'package:omnifit_front/constants/constants.dart';
import 'package:omnifit_front/models/user_data.dart';
import 'package:omnifit_front/page/users_page.dart';
import 'package:omnifit_front/service/app_service.dart';
import 'package:http/http.dart' as http;

class LoginPage extends StatefulWidget {
  static const route = '/login';

  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _obscureText = true;

  bool isInvalid = false;

  TextEditingController idController = TextEditingController();
  TextEditingController pwController = TextEditingController();

  @override
  void initState() {
    super.initState();

    idController.addListener(() {
      if(isInvalid) {
        isInvalid = false;
        setState(() {});
      }
    });

    pwController.addListener(() {
      if(isInvalid) {
        isInvalid = false;
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(
                child: _getFormUI(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getFormUI() {
    return Column(
      children: <Widget>[
        Container(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              svgIcon(Assets.img.icon_logo, width: 240, height: 80),
              const SizedBox(width: 10),
              Transform.translate(
                offset: const Offset(0, -6),
                child: Image.asset("assets/logo1.png", width: 309, height: 73)),
            ],
          ),
        ),
        const SizedBox(height: 50.0),
        TextFormField(
          controller: idController,
          keyboardType: TextInputType.emailAddress,
          autofocus: false,
          decoration: InputDecoration(
            hintText: 'ID',
            contentPadding: const EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(32.0)),
          ),
        ),
        const SizedBox(height: 20.0),
        TextFormField(
            controller: pwController,
            autofocus: false,
            obscureText: _obscureText,
            keyboardType: TextInputType.text,
            decoration: InputDecoration(
              hintText: 'PW',
              contentPadding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(32.0)),
              suffixIcon: GestureDetector(
                onTap: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
                child: Icon(
                  _obscureText ? Icons.visibility : Icons.visibility_off,
                  semanticLabel: _obscureText ? 'show password' : 'hide password',
                ),
              ),
            )),
        Container(
          width: 200,
          height: 80,
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.white,
            ),
            onPressed: () async {

              String id = idController.text;
              String pw = pwController.text;

              await callHttp(id, pw);
            },
            child: const Text('Log In', style: TextStyle(color: Colors.black)),
          ),
        ),
        const SizedBox(height: 20),
        if(isInvalid)
          const Text("로그인 실패했습니다.", style: TextStyle(color: Colors.redAccent)),
          const SizedBox(height: 20),
        Container(
          child: Text(
            'last update: 2025.10.27',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        )
      ],
    );
  }

  Future<void> callHttp(String id, String pw) async {

    final url = Uri.parse('${BASE_URL}api/v1/token-auth/');
    final response = await http.post(url, body: {
      "username": id,
      "password": pw
    });

    if (response.statusCode == 200) {

      Map valueMap = jsonDecode(response.body);

      AppService.instance.setUserData(UserData(
          id: valueMap['access']
      ));

      // AppService.instance.setUserData(UserData(
      //   id: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoiYWNjZXNzIiwiZXhwIjoxODA0Njg0ODk4LCJpYXQiOjE3MTgyODQ4OTgsImp0aSI6ImMyZWRhZGU0ZDMwYzQzMTA5MzU3MWIxMWE3MGQzODg5IiwidXNlcl9pZCI6MSwibmFtZSI6ImJyYWlubGFiIiwiaXNfc3RhZmYiOnRydWV9.TRhXu5DBKpx0T84r9EWxcDyCp2P1N5f4sj6-u1hr0mI'
      // ));

      context.go(UsersPage.route);
    }

    isInvalid = true;


    setState(() {});
  }
}
