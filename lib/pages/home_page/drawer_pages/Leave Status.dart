import 'package:flutter/material.dart';

class LeaveStatus extends StatefulWidget {
  const LeaveStatus ({super.key});

  @override
  State<LeaveStatus> createState() => _State();
}

class _State extends State<LeaveStatus> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
    appBar: AppBar(
    title:Text("Leave Status",style: TextStyle(color: Colors.white),) ,
backgroundColor: Colors.pink.shade800,
    ),
    );
  }
}
