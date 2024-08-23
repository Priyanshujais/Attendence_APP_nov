import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Profile_Screen extends StatefulWidget {
  const Profile_Screen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<Profile_Screen> {
  final Map<String, TextEditingController> _controllers = {
    'Full Name': TextEditingController(),
    'Employee ID': TextEditingController(),
    'Company': TextEditingController(),
    'Project': TextEditingController(),
    'Mobile': TextEditingController(),
    'Email ID': TextEditingController(),
    'Shift': TextEditingController(),  // Added Shift field
  };

  bool _isLoading = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    const String apiUrl = 'http://35.154.148.75/zarvis/api/v3/user';

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token == null) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
        return;
      }

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final userDetails = data['userDetails'];

        _controllers['Full Name']?.text = '${userDetails['first_name']} ${userDetails['last_name']}';
        _controllers['Employee ID']?.text = userDetails['emp_code'];
        _controllers['Company']?.text = userDetails['comp_name'];
        _controllers['Project']?.text = userDetails['project_name'];
        _controllers['Mobile']?.text = userDetails['phone_no'];
        _controllers['Email ID']?.text = userDetails['email'];
        _controllers['Shift']?.text = userDetails['shift_code'];
        String shift = userDetails['shift_code'];
        switch (shift) {
          case 'SHIFT-1':
            _controllers['Shift']?.text = 'Morning shift';
            break;
          case 'SHIFT-2':
            _controllers['Shift']?.text = 'Evening shift';
            break;
          case 'SHIFT-3':
            _controllers['Shift']?.text = 'General shift';
            break;
          default:
            _controllers['Shift']?.text = 'Unknown shift';
        }


        setState(() {
          _isLoading = false;
          _hasError = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load user data: ${response.statusCode}'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
            backgroundColor: Colors.redAccent,
            margin: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
          ),
        );
        print('Response body: ${response.body}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      print('Error fetching user data: $e');
    }
  }

  @override
  void dispose() {
    _controllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, designSize: Size(360, 690), minTextAdapt: true);

    return SafeArea(
      top: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "Profile",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.2,
                child: Image.asset(
                  "assets/images/zarvis.png",
                ),
              ),
            ),
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.all(25.w),
                    child: ListView(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      children: [
                        ..._controllers.keys.map((label) {
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: 10.h),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold,
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
                                  child: TextFormField(
                                    controller: _controllers[label],
                                    readOnly: true,
                                    decoration: InputDecoration(
                                      contentPadding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 10.w),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        borderSide: BorderSide.none,
                                      ),
                                      labelText: '',
                                      hintText: 'Enter your $label',
                                      hintStyle: TextStyle(
                                        fontSize: 12.sp,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
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
            if (_hasError)
              Center(
                child: Text('Failed to load user data. Please try again later.'),
              ),
          ],
        ),
      ),
    );
  }
}