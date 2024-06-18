import 'package:flutter/material.dart';

class AppRating extends StatelessWidget {
  const AppRating({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "App Rating",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red,
      ),
      body: Positioned.fill(
        child: Center(
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
