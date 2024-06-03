import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({Key? key});

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
        backgroundColor: Colors.pink.shade800,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo and Select Date TextField
            Row(
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
                        child: TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Select Date',
                            suffixIcon: IconButton(
                              onPressed: () => _selectDate(context),
                              icon: Icon(Icons.calendar_today),
                            ),
                            border: OutlineInputBorder(),
                          ),
                          controller: TextEditingController(
                            text: '${selectedDate.year}-${selectedDate.month}-${selectedDate.day}',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Submit Button
            ElevatedButton(
              onPressed: () {
                // Button onPressed action
              },
              child: Text('Submit',style: TextStyle(color: Colors.white),),
              style: ElevatedButton.styleFrom(
               backgroundColor: Colors.pink.shade800,// Text color
                elevation: 3, // Button shadow
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10), // Button border radius
                ),
                padding: EdgeInsets.symmetric(horizontal: 150, vertical: 15), // Button padding
              ),
            ),
          ],
        ),
      ),
    );
  }
}
