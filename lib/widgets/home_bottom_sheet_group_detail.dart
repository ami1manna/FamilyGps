import 'package:flutter/material.dart';

class  HomeBottomSheetGroupDetail extends StatefulWidget {
   HomeBottomSheetGroupDetail({super.key, required this.title ,required this.members});
  
  String title;
  List<String> members = [];
  @override
  State<HomeBottomSheetGroupDetail> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<HomeBottomSheetGroupDetail> {
  @override
  Widget build(BuildContext context) {
    return  Text(widget.title);
  }
}