import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../Login_pages/forgetpass_screen/forget_password.dart';
import '../Login_pages/signup_screen/sign_up_page.dart';
import '../home_page/HomeScreen.dart';
import 'models/login_model.dart';

bool _isLoading = false;

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController idController = TextEditingController();
  TextEditingController passController = TextEditingController();
  bool _obscureText = true;
  double screenHeight = 0.h;
  double screenWidth = 0.w;

  Color primary = Colors.redAccent;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    String emp_code = idController.text;
    String password = passController.text;

    var url = Uri.parse('http://35.154.148.75/zarvis/api/v2/login');
    var response = await http.post(url,
        body: jsonEncode({
          'emp_code': emp_code,
          'password': password,
        }),
        headers: {'Content-Type': 'application/json'});

    setState(() {
      _isLoading = false;
    });

    if (response.statusCode == 200) {
      Map<String, dynamic> responsedata = jsonDecode(response.body);

      log(responsedata.toString());
      LoginModel loginModel = LoginModel.fromJson(responsedata);
      if (loginModel.status == '1') {
        String? tokenn = responsedata['result']['token'];
        String? emp_nqme =
        responsedata['result']['employeedetails']['first_name'];
        int? companyId =
        responsedata['result']['employeedetails']['company_id'];
        String? empCode = responsedata['result']['employeedetails']['emp_code'];
        int? clientId = responsedata['result']['employeedetails']['client_id'];
        int? projectId =
        responsedata['result']['employeedetails']['project_id'];
        int? locationId =
        responsedata['result']['employeedetails']['location_id'];
        int? UserId = responsedata['result']['employeedetails']['user_id'];

        log("Token----$tokenn");

        SharedPreferences prefs = await SharedPreferences.getInstance();

        await prefs.setBool('isLoggedIn', true);
        await prefs.setString("token", tokenn!);
        await prefs.setString("emp_name", emp_nqme!);
        await prefs.setString("company_id", companyId.toString());
        await prefs.setString("emp_code", empCode!);
        await prefs.setString("user_id", UserId.toString()!);
        await prefs.setString("location_id", locationId.toString()!);
        await prefs.setString("project_id", projectId.toString()!);
        await prefs.setString("client_id", clientId.toString()!);

        log('Login successful, navigating to home screen');
        List<dynamic> permissions = responsedata['result']['permissions'];

        if (permissions.length > 1) {
          await prefs.setBool('isManager', true);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => Homescreen(
                deviceId: "cb7d119b9e3c8acb",
                token: tokenn,
                companyId: companyId.toString(),
                empCode: emp_code.toString(),
                userId: UserId.toString(),
                clientId: clientId.toString(),
                projectCode: projectId.toString(),
                locationId: locationId.toString(),
              ),
            ),
          );
        } else {
          await prefs.setBool('isManager', false);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => Homescreen(
                token: tokenn,
                companyId: companyId.toString(),
                empCode: emp_code,
                userId: UserId.toString(),
                clientId: clientId.toString(),
                projectCode: projectId.toString(),
                locationId: locationId.toString(),
                deviceId: "cb7d119b9e3c8acb",
              ),
            ),
          );
        }
      } else {
        log('Login failed: ${loginModel.message}');
        _showErrorDialog(loginModel.message ?? 'Login failed');
      }
    } else {
      _showErrorDialog('Server error: ${response.statusCode}');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Authentication Failed'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> storeToken(String token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  @override
  @override
  Widget build(BuildContext context) {
    bool isKeyboardVisible =
    KeyboardVisibilityProvider.isKeyboardVisible(context);
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                if (!isKeyboardVisible)
                  SizedBox(height: isKeyboardVisible ? 110 : 20),
                Container(
                  height: screenHeight / 3,
                  width: screenWidth,
                  child: Center(
                    child: Image.asset(
                      'assets/images/zarvis.png',
                      width: screenWidth / 1.5,
                      height: screenHeight / 3,
                    ),
                  ),
                ),
                Text(
                  "Login",
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: screenHeight / 30),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      fieldTile("Employee ID"),
                      customField("Enter your Employee id", idController, false),
                      fieldTile("Password"),
                      customField("Enter your Password", passController, true),
                      SizedBox(height: screenHeight / 50),
                      GestureDetector(
                        onTap: _login,
                        child: Container(
                          height: 40.h,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: primary,
                            borderRadius: BorderRadius.all(Radius.circular(32.r)),
                          ),
                          child: Center(
                            child: Text(
                              "LOGIN",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18.sp,
                                color: Colors.white,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ForgetPass(),
                                ),
                              );
                            },
                            child: Text(
                              'Forgot Password?',
                              style: TextStyle(
                                fontSize: 15.sp,
                                color: primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(width: 90.w),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SignupScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'Sign Up',
                              style: TextStyle(
                                fontSize: 15.sp,
                                color: primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  Widget fieldTile(String title) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget customField(
      String hint, TextEditingController controller, bool obscure) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(12.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10.r,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50.w,
            child: Icon(
              hint == 'Enter your Password' ? Icons.lock : Icons.person,
              color: primary,
              size: 24.sp,
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: 16.w),
              child: TextFormField(
                controller: controller,
                enableSuggestions: false,
                autocorrect: false,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 16.h,
                  ),
                  border: InputBorder.none,
                  hintText: hint,
                ),
                maxLines: 1,
                obscureText: obscure && _obscureText,
              ),
            ),
          ),
          if (hint == 'Enter your Password')
            IconButton(
              icon: Icon(
                _obscureText ? Icons.visibility_off : Icons.visibility,
                color: primary,
              ),
              onPressed: () {
                setState(() {
                  _obscureText = !_obscureText;
                });
              },
            ),
        ],
      ),
    );
  }
}
