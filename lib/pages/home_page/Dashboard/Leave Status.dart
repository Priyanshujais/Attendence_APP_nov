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
backgroundColor: Colors.red,
    ),
      body: Center(
        child: Positioned.fill(
          child: Opacity(
            opacity: 0.2, // Adjust the opacity as needed
            child: Image.asset(
              "assets/images/zarvis.png",
              // fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}
