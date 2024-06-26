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
  // Define a map to hold the field data
  final Map<String, TextEditingController> _controllers = {
    'Full Name': TextEditingController(),
    'Employee ID': TextEditingController(),
    'Company': TextEditingController(),
    'Project': TextEditingController(),
    'Mobile': TextEditingController(),
    'Email ID': TextEditingController(),
  };

  @override
  void initState() {
    super.initState();
    // Fetch data from the API and populate the controllers
    _fetchData();
  }

  Future<void> _fetchData() async {
    const String apiUrl = 'http://35.154.148.75/zarvis/api/v2/user';

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token'); // Retrieve the token from SharedPreferences

      if (token == null) {
        print('Token is null');
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

        // Populate the controllers with the data from the API
        _controllers['Full Name']?.text = '${userDetails['first_name']} ${userDetails['last_name']}';
        _controllers['Employee ID']?.text = userDetails['emp_code'];
        _controllers['Company']?.text = userDetails['comp_name'];
        _controllers['Project']?.text = userDetails['project_name'];
        _controllers['Mobile']?.text = userDetails['phone_no'];
        _controllers['Email ID']?.text = userDetails['email'];

        // Update the state to refresh the UI
        setState(() {});
      } else {
        // Handle the case where the server returns an error
        print('Failed to load user data: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      // Handle the case where there is a network error
      print('Error fetching user data: $e');
    }
  }

  @override
  void dispose() {
    // Dispose of the controllers when the widget is disposed
    _controllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, designSize: Size(360, 690), minTextAdapt: true);

    return SafeArea(top: true
      ,
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
            // Background image with low visibility
            Positioned.fill(
              child: Opacity(
                opacity: 0.2, // Adjust the opacity as needed
                child: Image.asset(
                  "assets/images/zarvis.png",
                 // fit: BoxFit.,
                ),
              ),
            ),
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Form fields
                  Padding(
                    padding: EdgeInsets.all(25.w),
                    child: ListView(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      children: [
                        // Loop through the controllers map to create form fields
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
                                    readOnly: true, // Make the text fields read-only
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
          ],
        ),
      ),
    );
  }
}
