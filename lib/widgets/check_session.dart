
import 'package:familygps/controllers/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class CheckSession extends StatefulWidget {
  const CheckSession({super.key});

  @override
  State<CheckSession> createState() => _CheckSessionState();
}

class _CheckSessionState extends State<CheckSession> {
  @override
  void initState() {
    super.initState();
    checkSession().then((value){
      if(value == true){
        Navigator.pushReplacementNamed(context, '/home');
      }
      else{
        Navigator.pushReplacementNamed(context, '/signup');
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body:Center(
        child: CircularProgressIndicator(),
      )
    );
  }
}