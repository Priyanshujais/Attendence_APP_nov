import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../LoginScreen.dart';

class ForgetPass extends StatefulWidget {
  const ForgetPass({super.key});

  @override
  State<ForgetPass> createState() => _ForgetPassState();
}

class _ForgetPassState extends State<ForgetPass> {
  TextEditingController idController = TextEditingController();
  TextEditingController emailController = TextEditingController();

  Future<void> _forgetPassword() async {
    String empId = idController.text;
    String email = emailController.text;

    if (empId.isEmpty || email.isEmpty) {
      _showErrorDialog('Please fill in all fields');
      return;
    }

    try {
      var url = Uri.parse('http://35.154.148.75/zarvis/api/v3/forgetPassword');
      var response = await http.post(
        url,
        body: jsonEncode({
          'emp_code': empId,
          'email': email,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> responsedata = jsonDecode(response.body);
        String status = responsedata['status'];
        String message = responsedata['message'];

        if (status == '0') {
          _showErrorDialog(message);
        } else {
          _showSuccessDialog(message);
        }
      } else {
        _showErrorDialog('Server error: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorDialog('An error occurred: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Success'),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => LoginScreen(),
                  ),
                      (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0), // Added padding for better layout
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                height: MediaQuery.of(context).size.height * 0.35,
                decoration: const BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.only(
                    bottomRight: Radius.circular(80),
                  ),
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/zarvis.png',
                    width: MediaQuery.of(context).size.height * 0.25,
                    height: MediaQuery.of(context).size.height * 0.25,
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                "Forget Password",
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width * 0.05,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  fieldTile("Employee ID"),
                  customField("Enter your Employee ID", idController, false, Icons.person), // Updated icon here
                  fieldTile("Email"),
                  customField("Enter your Email", emailController, false, Icons.email_outlined),
                  GestureDetector(
                    onTap: _forgetPassword,
                    child: Container(
                      height: 60,
                      width: double.infinity, // Changed to double.infinity for full width
                      margin: const EdgeInsets.only(top: 20),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: Center(
                        child: Text(
                          "Submit",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: MediaQuery.of(context).size.width * 0.04,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget fieldTile(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: MediaQuery.of(context).size.width * 0.04,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget customField(String hint, TextEditingController controller, bool obscure, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16), // Added side margins
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Icon(
              icon,
              color: Colors.red,
              size: MediaQuery.of(context).size.width * 0.06,
            ),
          ),
          Expanded(
            child: TextFormField(
              controller: controller,
              enableSuggestions: false,
              autocorrect: false,
              decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(
                  vertical: MediaQuery.of(context).size.height * 0.02,
                ),
                border: InputBorder.none,
                hintText: hint,
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}