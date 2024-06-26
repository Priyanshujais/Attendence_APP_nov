import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ManagerLeaveApproval extends StatefulWidget {
  const ManagerLeaveApproval({Key? key}) : super(key: key);

  @override
  State<ManagerLeaveApproval> createState() => _ManagerLeaveApprovalState();
}

class _ManagerLeaveApprovalState extends State<ManagerLeaveApproval> {
  int pendingCount = 0;
  int approvedCount = 0;
  int declinedCount = 0;
  List<Map<String, dynamic>> leaveData = [];

  // Page controller for swipe navigation
  late PageController _pageController;
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    fetchLeaveData();
    _pageController = PageController(initialPage: 0);
  }

  Future<void> fetchLeaveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      String? empCode = prefs.getString('emp_code');
      String? compId = prefs.getString('company_id');

      if (token == null || empCode == null || compId == null) {
        print('Error: Token, Emp Code, or Comp ID is null.');
        return;
      }

      final url = Uri.parse('http://35.154.148.75/zarvis/api/v2/managerleavehistory');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'emp_code': empCode,
          'comp_id': compId,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        print('Leave data response: $jsonResponse');

        if (jsonResponse['status'] == '1') {
          setState(() {
            pendingCount = jsonResponse['pendingcount'] ?? 0;
            approvedCount = jsonResponse['approvedcount'] ?? 0;
            declinedCount = jsonResponse['declinedcount'] ?? 0;

            if (jsonResponse['pending'] != null && jsonResponse['pending'] is List) {
              List<dynamic> pendingData = jsonResponse['pending'];
              leaveData = pendingData
                  .where((leave) => leave is Map<String, dynamic>)
                  .map((leave) => leave as Map<String, dynamic>)
                  .toList();
            }

            if (jsonResponse['approved'] != null && jsonResponse['approved'] is List) {
              List<dynamic> approvedData = jsonResponse['approved'];
              leaveData.addAll(
                approvedData
                    .where((leave) => leave is Map<String, dynamic>)
                    .map((leave) => leave as Map<String, dynamic>)
                    .toList(),
              );
            }

            if (jsonResponse['declined'] != null && jsonResponse['declined'] is List) {
              List<dynamic> declinedData = jsonResponse['declined'];
              leaveData.addAll(
                declinedData
                    .where((leave) => leave is Map<String, dynamic>)
                    .map((leave) => leave as Map<String, dynamic>)
                    .toList(),
              );
            }
          });
        } else {
          // Handle API error scenario
          print('API returned status 0 or other error: ${jsonResponse['message']}');
        }
      } else {
        // Handle HTTP error scenario
        print('Failed to load leave data: ${response.statusCode}');
      }
    } catch (e) {
      // Handle other errors like network issues, etc.
      print('Exception: Failed to load leave data: $e');
    }
  }

  Future<void> _handleApproval(String leaveId) async {
    // Show dialog for comment input
    String? comment = await _showCommentDialog();

    if (comment != null) {
      await _updateLeaveStatus(leaveId, '1', comment);
    }
  }

  Future<void> _handleRejection(String leaveId) async {
    // Show dialog for comment input
    String? comment = await _showCommentDialog();

    if (comment != null) {
      await _updateLeaveStatus(leaveId, '0', comment);
    }
  }

  Future<String?> _showCommentDialog() async {
    TextEditingController commentController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Leave Comment'),
          content: TextField(
            controller: commentController,
            decoration: InputDecoration(hintText: 'Enter your comment'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(commentController.text);
              },
              child: Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateLeaveStatus(String leaveId, String status, String comment) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      String? empCode = prefs.getString('emp_code');

      if (token == null || empCode == null) {
        print('Error: Token or Emp Code is null.');
        return;
      }

      final url = Uri.parse('http://35.154.148.75/zarvis/api/v2/updateleavestatus');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'leave_id': leaveId,
          'emp_code': empCode,
          'leavestatus': status,
          'leavemessage': comment,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        print('Leave status update response: $jsonResponse');

        if (jsonResponse['status'] == '1') {
          // Handle success scenario
          print('Leave status updated successfully!');
          // Optionally, you can update the UI or perform additional actions upon successful update
        } else {
          // Handle API error scenario
          print('Failed to update leave status: ${jsonResponse['message']}');
        }
      } else {
        // Handle HTTP error scenario
        print('Failed to update leave status: ${response.statusCode}');
      }
    } catch (e) {
      // Handle other errors like network issues, etc.
      print('Exception: Failed to update leave status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Manager Leave Approval",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildInfoContainer(
                  "Pending",
                  pendingCount.toString(),
                  Colors.blueAccent,
                  0,
                ),
                _buildInfoContainer(
                  "Approved",
                  approvedCount.toString(),
                  Colors.green,
                  1,
                ),
                _buildInfoContainer(
                  "Rejected",
                  declinedCount.toString(),
                  Colors.red,
                  2,
                ),
              ],
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPageIndex = index;
                });
              },
              children: [
                _buildLeaveList(
                  leaveData
                      .where((leave) => leave['status'] == 'pending')
                      .toList(),
                ),
                _buildLeaveList(
                  leaveData
                      .where((leave) => leave['status'] == 'approved')
                      .toList(),
                ),
                _buildLeaveList(
                  leaveData
                      .where((leave) => leave['status'] == 'declined')
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoContainer(
      String title,
      String value,
      Color color,
      int index,
      ) {
    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(
          index,
          duration: Duration(milliseconds: 500),
          curve: Curves.ease,
        );
      },
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.8), color],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeaveList(List<Map<String, dynamic>> leaves) {
    return ListView.builder(
        itemCount: leaves.length,
        itemBuilder: (context, index) {
      final leave = leaves[index];
      return Padding(
          padding: const EdgeInsets.all(8.0),
    child: Card
      (
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'From: ${leave['leave_from_date']}',
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            Text(
              'To: ${leave['leave_to_date']}',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              'Applied on: ${leave['created_at']}',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              'Employee Code: ${leave['emp_code']}',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              '${leave['first_name']}',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              'Reason: ${leave['Subject']}',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              'Remarks: ${leave['leave_message']}',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              'Leave Type: ${leave['leave_type'] ?? 'Not specified'}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            if (leave['status'] == 'pending')
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () =>
                        _handleApproval(leave['id'].toString()),
                    child: Text(
                      'Accept',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () =>
                        _handleRejection(leave['id'].toString()),
                    child: Text(
                      'Reject',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade900,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    ),
      );
        },
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
