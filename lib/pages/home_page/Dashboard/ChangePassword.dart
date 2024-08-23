import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../HomeScreen.dart';

class ChangePassword extends StatefulWidget {
  const ChangePassword({Key? key}) : super(key: key);

  @override
  State<ChangePassword> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isObscureOldPassword = true;
  bool _isObscureNewPassword = true;
  bool _isObscureConfirmPassword = true;

  void _toggleOldPasswordVisibility() {
    setState(() {
      _isObscureOldPassword = !_isObscureOldPassword;
    });
  }

  void _toggleNewPasswordVisibility() {
    setState(() {
      _isObscureNewPassword = !_isObscureNewPassword;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _isObscureConfirmPassword = !_isObscureConfirmPassword;
    });
  }

  Future<void> _changePassword() async {
    final String oldPassword = _oldPasswordController.text;
    final String newPassword = _newPasswordController.text;
    final String confirmPassword = _confirmPasswordController.text;

    if (oldPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all the fields')),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New password and confirm password do not match')),
      );
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString("token") ?? "";
    print("Token: $token");

    final url = Uri.parse('http://35.154.148.75/zarvis/api/v3/changePassWithOldPass');

    try {
      final response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(<String, String>{
          'old_password': oldPassword,
          'new_password': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = jsonDecode(response.body);
        String status = responseData['status'];
        String message = responseData['message'];

        if (status == '1') {
          print(responseData);
          _showSuccessDialog(message);
        } else {
          print(responseData);
          _showErrorDialog(message);
        }
      } else {
        print('HTTP Error ${response.statusCode}: ${response.reasonPhrase}');
        _showErrorDialog('Failed to change password');
      }
    } catch (e) {
      print('Exception during HTTP request: $e');
      _showErrorDialog('An error occurred: $e');
    }
  }
  Future<void> saveDataToSharedPreferences() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setString('deviceId', 'yourDeviceId');
    await prefs.setString('empCode', 'yourEmpCode');
    await prefs.setString('userId', 'yourUserId');
    await prefs.setString('clientId', 'yourClientId');
    await prefs.setString('projectCode', 'yourProjectCode');
    await prefs.setString('locationId', 'yourLocationId');
    await prefs.setString('companyId', 'yourCompanyId');
    await prefs.setString('token', 'yourToken');
  }

  Future<void> _showSuccessDialog(message

      ) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
      // Retrieve the data from SharedPreferences
         String deviceId = prefs.getString('deviceId') ?? '';
         String empCode = prefs.getString('empCode') ?? '';
         String userId = prefs.getString('userId') ?? '';
         String clientId = prefs.getString('clientId') ?? '';
         String projectCode = prefs.getString('projectCode') ?? '';
         String locationId = prefs.getString('locationId') ?? '';
         String companyId = prefs.getString('companyId') ?? '';
         String token = prefs.getString('token') ?? '';



    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Success"),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => Homescreen(
                      token: token,
                      locationId: locationId,
                      userId: userId,
                      projectCode: projectCode,
                      deviceId: deviceId,
                      clientId: clientId,
                      companyId: companyId,
                      empCode: empCode,
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Error"),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, designSize: Size(360, 690), minTextAdapt: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Change Password",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red,
      ),
      body: Stack(
        children: [
          // Background with low visibility and logo
          Positioned.fill(
            child: Opacity(
              opacity: 0.2, // Adjust the opacity as needed
              child: Image.asset(
                "assets/images/zarvis.png",
                // fit: BoxFit.cover,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Container(
                width: 320.w, // Adjust the width as needed
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(

                  borderRadius: BorderRadius.circular(20),
                  // boxShadow: const [
                  //   BoxShadow(
                  //     color: Colors.black26,
                  //     blurRadius: 6,
                  //     offset: Offset(0, 2),
                  //   ),
                  // ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTextField(
                      controller: _oldPasswordController,
                      labelText: 'Old Password',
                      isObscure: _isObscureOldPassword,
                      toggleVisibility: _toggleOldPasswordVisibility,
                    ),
                    SizedBox(height: 20.h),
                    _buildTextField(
                      controller: _newPasswordController,
                      labelText: 'New Password',
                      isObscure: _isObscureNewPassword,
                      toggleVisibility: _toggleNewPasswordVisibility,
                    ),
                    SizedBox(height: 20.h),
                    _buildTextField(
                      controller: _confirmPasswordController,
                      labelText: 'Confirm New Password',
                      isObscure: _isObscureConfirmPassword,
                      toggleVisibility: _toggleConfirmPasswordVisibility,
                    ),
                    SizedBox(height: 20.h),
                    ElevatedButton(
                      onPressed: _changePassword,
                      child: Text(
                        "Submit",
                        style: TextStyle(
                          fontSize: 18.sp,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 80.w,
                          vertical: 10.h,
                        ),backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required bool isObscure,
    required VoidCallback toggleVisibility,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: TextStyle(
            color: Colors.black,
            fontSize: 16.sp,
          ),
        ),
        SizedBox(height: 5.h),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            obscureText: isObscure,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 10.w),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  isObscure ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: toggleVisibility,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
