import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zarvis_app/pages/Login_pages/signup_screen/register_screen.dart';

class SignupScreen extends StatefulWidget {
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  TextEditingController employeeIdController = TextEditingController();
  String? selectedValue;
  List<String> companyList = [];
  String com_id = "";

  @override
  void initState() {
    super.initState();
    _fetchCompanies();
  }

  Future<void> _fetchCompanies() async {
    try {
      final response = await http.get(Uri.parse('http://35.154.148.75/zarvis/api/v4/companyList'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> companies = data['dataset'];
        setState(() {
          companyList = companies.map((company) => company['comp_name'].toString()).toList();
          com_id = data['dataset'][0]['comp_id'].toString();
          print(com_id);
        });
      } else {
        print('Failed to load companies');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _verifyEmployee() async {
    String employeeId = employeeIdController.text;
    String company = selectedValue ?? "";

    try {
      final response = await http.post(
        Uri.parse('http://35.154.148.75/zarvis/api/v4/verifyEmployee'),
        body: json.encode({'emp_code': employeeId, 'comp_id': com_id}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['status'] == "1" && responseData['flag'] == "2") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RegisterScreen(
                comp_id: com_id,
                emp_code: employeeId,
              ),
            ),
          );
        } else {
          _showDialog('Signup Failed', responseData['message']);
        }
      } else {
        _showDialog('Signup Failed', 'Failed to verify Employee ID. Please try again later.');
      }
    } catch (e) {
      print('Error: $e');
      _showDialog('Signup Failed', 'An error occurred. Please try again later.');
    }
  }

  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // This allows the body to resize when the keyboard appears
      body: SingleChildScrollView( // Wrap the content in SingleChildScrollView
        child: Column(
          children: [
            Container(
              height: MediaQuery.of(context).size.height / 2.9,
              width: MediaQuery.of(context).size.width / 2.0,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(80),
                ),
              ),
              child: Center(
                child: Image.asset(
                  'assets/images/zarvis.png',
                  width: MediaQuery.of(context).size.height / 3,
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.only(
                top: MediaQuery.of(context).size.width / 25,
                bottom: MediaQuery.of(context).size.height / 20,
              ),
              child: Text(
                "Sign Up",
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width / 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              alignment: Alignment.centerLeft,
              margin: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width / 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.black26),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.redAccent),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'Select Company',
                      hintStyle: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 15.h,
                        horizontal: 20.w,
                      ),
                    ),
                    value: selectedValue,
                    items: companyList.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      setState(() {
                        selectedValue = value;
                        print("this is selected ${selectedValue}");
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  fieldTile("Employee ID"),
                  customField("Enter your Employee ID", employeeIdController, false),
                  SizedBox(height: 30.h),
                  GestureDetector(
                    onTap: _verifyEmployee,
                    child: Container(
                      height: 50,
                      width: MediaQuery.of(context).size.width,
                      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height / 40),
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.all(Radius.circular(32)),
                      ),
                      child: Center(
                        child: Text(
                          "SIGNUP",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: MediaQuery.of(context).size.width / 26,
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
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget customField(String hint, TextEditingController controller, bool obscure) {
    return Container(
      width: MediaQuery.of(context).size.width,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(12)),
        boxShadow: [
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
            width: MediaQuery.of(context).size.width / 6,
            child: Icon(
              Icons.person,
              color: Colors.redAccent,
              size: MediaQuery.of(context).size.width / 15,
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: MediaQuery.of(context).size.width / 15),
              child: TextFormField(
                controller: controller,
                enableSuggestions: false,
                autocorrect: false,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    vertical: MediaQuery.of(context).size.height / 35,
                  ),
                  border: InputBorder.none,
                  hintText: hint,
                ),
                maxLines: 1,
                obscureText: obscure,
              ),
            ),
          ),
        ],
      ),
    );
  }
}