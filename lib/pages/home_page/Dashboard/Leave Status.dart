import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LeaveStatus extends StatefulWidget {
  const LeaveStatus({Key? key});

  @override
  State<LeaveStatus> createState() => _LeaveStatusState();
}

class _LeaveStatusState extends State<LeaveStatus> {
  List<dynamic> leaveData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchLeaveHistory();
  }

  Future<void> fetchLeaveHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? empCode = prefs.getString('emp_code');
    String? token = prefs.getString('token');

    if (empCode != null && token != null) {
      final response = await http.post(
        Uri.parse('http://35.154.148.75/zarvis/api/v4/LeaveHistory'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(<String, String>{
          'emp_code': empCode,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == '0' && responseData['message'] == 'No history found') {
          setState(() {
            leaveData = []; // Clear existing data
            isLoading = false;
          });
        } else {
          setState(() {
            leaveData = responseData['data'];
            isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load leave history');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Leave Status",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : leaveData.isEmpty
          ? Center(child: Text('No leave history available'))
          : ListView.builder(
        itemCount: leaveData.length,
        itemBuilder: (context, index) {
          var leave = leaveData[index];
          return Container(
            margin: EdgeInsets.all(10.0),
            padding: EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('From: ${leave['leave_from_date']}',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('To: ${leave['leave_to_date']}',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(height: 5.0),
                Text('Applied on: ${leave['created_at']}',
                    style: TextStyle(color: Colors.grey)),
                SizedBox(height: 5.0),
                Text('Reason: ${leave['Subject'] ?? 'No Subject'}',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 5.0),
                Text('User Remarks: ${leave['leave_message'] ?? 'No Remarks'}',
                    style: TextStyle(color: Colors.grey)),
                SizedBox(height: 5.0),
                Text('Status: ${leave['status'] ?? 'No Status'}',
                    style: TextStyle(color: Colors.grey)),
                SizedBox(height: 5.0),
                Text('Leave Type: ${leave['leave_type'] ?? 'No Type'}',
                    style: TextStyle(color: Colors.grey)),
                SizedBox(height: 5.0),
                Text('Manager Remarks: ${leave['status_message'] ?? 'No Remarks'}',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        },
      ),
    );
  }
}
