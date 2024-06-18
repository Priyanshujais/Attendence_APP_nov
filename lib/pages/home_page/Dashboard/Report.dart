import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({Key? key}) : super(key: key);

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  DateTime selectedDate = DateTime.now();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Report",
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
                'assets/images/zarvis.png', // Replace with your background image path
                //fit: BoxFit.cover,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo and Select Date TextField
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Image.asset(
                        'assets/images/zarvis.png', // Replace with your logo asset
                        width: 120.w,
                        height: 120.h,
                      ),
                    ),
                    // Select Date TextField
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: InkWell(
                          onTap: () => _selectDate(context),
                          child: AbsorbPointer(
                            child: Container(
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
                                decoration: InputDecoration(
                                  labelText: 'Select Date',
                                  labelStyle: TextStyle(color: Colors.black),
                                  suffixIcon: IconButton(
                                    onPressed: () => _selectDate(context),
                                    icon: Icon(Icons.calendar_today),
                                    color: Colors.red,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding:
                                  EdgeInsets.symmetric(vertical: 10.h, horizontal: 10.w),
                                ),
                                controller: TextEditingController(
                                  text:
                                  '${selectedDate.year}-${selectedDate.month}-${selectedDate.day}',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                // Submit Button
                ElevatedButton(
                  onPressed: () {
                    // Button onPressed action
                  },
                  child: Text(
                    'Submit',
                    style: TextStyle(color: Colors.white, fontSize: 18.sp),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 80.w, vertical: 15.h),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
