import 'package:flutter/material.dart';

class Teamreport extends StatefulWidget {
  const Teamreport({super.key});

  @override
  State<Teamreport> createState() => _TeamreportState();
}

class _TeamreportState extends State<Teamreport> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(
      title: Text(
        "Team Report",
        style: TextStyle(color: Colors.white),
      ),
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
