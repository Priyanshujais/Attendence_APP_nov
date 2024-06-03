import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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
    // Simulate an API call with sample data
    await Future.delayed(Duration(seconds: 2)); // Simulate network delay

    // Example data from API
    Map<String, String> apiData = {
      'Full Name': 'Priyanshu Jaiswal ',
      'Employee ID': 'E4812',
      'Company': 'Globtier infotech PVT LTD',
      'Project': 'Globtier internal',
      'Mobile': '9695778034',
      'Email ID': 'abc@gmail.com',
    };

    // Populate the controllers with the data from the API
    apiData.forEach((key, value) {
      if (_controllers.containsKey(key)) {
        _controllers[key]?.text = value;
      }
    });

    // Update the state to refresh the UI
    setState(() {});
  }

  @override
  void dispose() {
    // Dispose of the controllers when the widget is disposed
    _controllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Profile",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.pink.shade800,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo at the top
            Padding(
              padding: EdgeInsets.only(top: 20.h),
              child: Center(
                child: Image.asset(
                  "assets/images/zarvis.png",
                  height: 80.h,
                  width: 80.w,
                ),
              ),
            ),
            // Form fields
            SizedBox(
              height: MediaQuery.of(context).size.height,
              child: Padding(
                padding: EdgeInsets.all(25.w),
                child: ListView(
                  children: [
                    // Loop through the controllers map to create form fields
                    ..._controllers.keys.map((label) {
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 1.h),
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
                            SizedBox(height: 1.h),
                            TextField(
                              controller: _controllers[label],
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(9.0),
                                ),
                                labelText: '',
                                hintText: 'Enter your $label',
                                hintStyle: TextStyle(
                                  fontSize: 12.sp,
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
            ),
          ],
        ),
      ),
    );
  }
}
