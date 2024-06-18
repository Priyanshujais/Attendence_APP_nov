import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ForgetPass extends StatefulWidget {
  const ForgetPass({super.key});

  @override
  State<ForgetPass> createState() => _ForgetPassState();
}

class _ForgetPassState extends State<ForgetPass> {
  TextEditingController idController = TextEditingController();
  TextEditingController emailController = TextEditingController();

  double screenHeight = 0;
  double screenWidth = 0;

  Future<void> _forgetPassword() async {
    String empId = idController.text;
    String email = emailController.text;

    if (empId.isEmpty || email.isEmpty) {
      _showErrorDialog('Please fill in all fields');
      return;
    }

    try {
      var url = Uri.parse('http://35.154.148.75/zarvis/api/v2/forgetPassword');
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
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: screenHeight / 2.7,
              width: screenWidth / 2.0,
              decoration: const BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(80),
                ),
              ),
              child: Center(
                child: Image.asset(
                  'assets/images/zarvis.png',
                  width: screenHeight / 3,
                  height: screenHeight / 1,
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.only(
                top: screenWidth / 25,
                bottom: screenHeight / 20,
              ),
              child: Text(
                "Forget Password",
                style: TextStyle(
                  fontSize: screenWidth / 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              alignment: Alignment.centerLeft,
              margin: EdgeInsets.symmetric(horizontal: screenWidth / 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  fieldTile("Employee ID"),
                  customField("Enter your Employee id", idController, false),
                  fieldTile("Email"),
                  customField("Enter your Email", emailController, false),
                  GestureDetector(
                    onTap: _forgetPassword,
                    child: Container(
                      height: 60,
                      width: screenWidth,
                      margin: EdgeInsets.only(top: screenHeight / 40),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: Center(
                        child: Text(
                          "Submit",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: screenWidth / 26,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget fieldTile(String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: screenWidth / 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget customField(
      String hint, TextEditingController controller, bool obscure) {
    return Container(
      width: screenWidth,
      margin: const EdgeInsets.only(bottom: 12),
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
          Container(
            width: screenWidth / 8,
            child: Icon(
              Icons.email_outlined,
              color: Colors.red,
              size: screenWidth / 15,
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: screenWidth / 15),
              child: TextFormField(
                controller: controller,
                enableSuggestions: false,
                autocorrect: false,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    vertical: screenHeight / 35,
                  ),
                  border: InputBorder.none,
                  hintText: hint,
                ),
                maxLines: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
