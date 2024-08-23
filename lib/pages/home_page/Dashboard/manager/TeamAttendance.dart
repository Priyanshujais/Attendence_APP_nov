import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import 'TeamAttendanceReport.dart';

class Teamattendance extends StatefulWidget {
  const Teamattendance({Key? key}) : super(key: key);

  @override
  State<Teamattendance> createState() => _TeamattendanceState();
}

class _TeamattendanceState extends State<Teamattendance> {
  List<Map<String, dynamic>> clients = [];
  List<Map<String, dynamic>> projects = [];
  List<Map<String, dynamic>> locations = [];
  String? selectedClient;
  String? selectedProject;
  String? selectedLocation;
  String? token;
  String? companyId;
  String? empCode;
  String clientResponse = '';
  String projectResponse = '';
  String locationResponse = '';
  String errorMessage = '';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchClientList();
  }

  Future<void> fetchClientList() async {
    setState(() {
      isLoading = true; // Set loading state to true when starting to fetch data
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      token = prefs.getString('token');
      companyId = prefs.getString('company_id');
      empCode = prefs.getString('emp_code'); // Fetch emp_code
      print('Token fetched from SharedPreferences: $token');
      print('Company ID fetched from SharedPreferences: $companyId');
      print('Employee Code fetched from SharedPreferences: $empCode');

      if (token != null && companyId != null) {
        final response = await http.post(
          Uri.parse('http://35.154.148.75/zarvis/api/v3/clientList'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'comp_id': companyId,
            'rm_emp_code': empCode,
          }),
        );

        if (response.statusCode == 200) {
          final jsonResponse = json.decode(response.body);
          print('Client list response: $jsonResponse');

          if (jsonResponse['status'] == '1' &&
              jsonResponse['dataset'] != null &&
              jsonResponse['dataset'] is List) {
            setState(() {
              clients = List<Map<String, dynamic>>.from(jsonResponse['dataset']);
              clientResponse = jsonResponse.toString();
            });
          } else {
            setState(() {
              errorMessage = jsonResponse['message'] ?? 'Invalid response format or status not 1';
            });
            throw Exception('Invalid response format or status not 1');
          }
        } else {
          setState(() {
            errorMessage = 'Failed to load clients: ${response.statusCode}';
          });
          throw Exception('Failed to load clients: ${response.statusCode}');
        }
      } else {
        setState(() {
          errorMessage = 'Token or company_id is null';
        });
        throw Exception('Token or company_id is null');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching clients: $e';
      });
      print('Error fetching clients: $e');
    }
    finally {
      setState(() {
        isLoading = false; // Set loading state to false once data is fetched
      });
    }
  }

  Future<void> fetchProjects(String clientId) async {
    setState(() {
      isLoading = true; // Set loading state to true when starting to fetch data
    });
    try {
      if (token != null && empCode != null) {
        final response = await http.post(
          Uri.parse('http://35.154.148.75/zarvis/api/v3/projectList'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'client_id': clientId,
            'emp_code': empCode,
          }),
        );

        print("this is client id $clientId");

        if (response.statusCode == 200) {
          final jsonResponse = json.decode(response.body);
          print('Project list response: $jsonResponse');

          if (jsonResponse['status'] == '1' ||
              jsonResponse['dataset'] != null ||
              jsonResponse['dataset'] is List) {
            setState(() {
              projects = List<Map<String, dynamic>>.from(jsonResponse['dataset']);
              projectResponse = jsonResponse.toString();
            });
          } else if (jsonResponse['status'] == '0') {
            String message = jsonResponse['message'];
            setState(() {
              errorMessage = jsonResponse['message'] ?? 'You are not associated with this client, kindly select relevant Client ! !';
              Get.snackbar(
                "Warning !",
                message,
                backgroundColor: Colors.white,
                colorText: Colors.black,
              );
              throw Exception(" status 0  Error fetching clients + You are not associated with this client, kindly select relevant Client !");
            });
          } else {
            setState(() {
              errorMessage = jsonResponse['message'] ?? 'Invalid response format or status not 1';
            });
            throw Exception('Invalid response format or status not 1');
          }
        } else {
          setState(() {
            errorMessage = 'Failed to load projects: ${response.statusCode}';
          });
          throw Exception('Failed to load projects: ${response.statusCode}');
        }
      } else {
        setState(() {
          errorMessage = 'Token or emp_code is null';
        });
        throw Exception('Token or emp_code is null');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching projects: $e';
      });
      print('Error fetching projects: $e');
    }
    finally {
      setState(() {
        isLoading = false; // Set loading state to false once data is fetched
      });
    }
  }

  Future<void> fetchLocations(String projectId) async {
    setState(() {
      isLoading = true; // Set loading state to true when starting to fetch data
    });
    try {
      if (token != null && empCode != null) {
        final response = await http.post(
          Uri.parse('http://35.154.148.75/zarvis/api/v3/locationList'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'project_id': projectId,
            'emp_code': empCode,
          }),
        );

        print("this is project id $projectId");
        print("this is emp code $empCode");

        if (response.statusCode == 200) {
          final jsonResponse = json.decode(response.body);
          print('Location list response: $jsonResponse');

          if (jsonResponse['status'] == '1' &&
              jsonResponse['dataset'] != null &&
              jsonResponse['dataset'] is List) {
            setState(() {
              locations = List<Map<String, dynamic>>.from(jsonResponse['dataset']);
              locationResponse = jsonResponse.toString();
            });
          } else {
            setState(() {
              errorMessage = jsonResponse['message'] ?? 'Invalid response format or status not 1';
            });
            throw Exception('Invalid response format or status not 1');
          }
        } else {
          setState(() {
            errorMessage = 'Failed to load locations: ${response.statusCode}';
          });
          throw Exception('Failed to load locations: ${response.statusCode}');
        }
      } else {
        setState(() {
          errorMessage = 'Token or emp_code is null';
        });
        throw Exception('Token or emp_code is null');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching locations: $e';
      });
      print('Error fetching locations: $e');
    }
    finally {
      setState(() {
        isLoading = false; // Set loading state to false once data is fetched
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Team Attendance",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red,
      ),
      body:isLoading
    ? Center(child: CircularProgressIndicator()) // Show loading indicator
        :
     Center( // Show error message

        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.2,
                child: Image.asset(
                  "assets/images/zarvis.png",
                  // fit: BoxFit.cover,
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Client'),
                      _buildCircularDropdown(
                        hint: "Select Client",
                        value: selectedClient,
                        items: clients.map((client) {
                          return DropdownMenuItem<String>(
                            value: client['id']?.toString(),
                            child: Text(client['client_name'] ?? 'Unknown'),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            selectedClient = newValue;
                            selectedProject = null;
                            selectedLocation = null;
                            projects = [];
                            locations = [];
                          });
                          fetchProjects(newValue!);
                        },
                      ),
                      if (selectedClient != null && projects.isNotEmpty) ...[
                        _buildLabel('Project'),
                        _buildCircularDropdown(
                          hint: "Select Project",
                          value: selectedProject,
                          items: projects.map((project) {
                            return DropdownMenuItem<String>(
                              value: project['project_id']?.toString(),
                              child: Text(project['project_name'] ?? 'Unknown'),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setState(() {
                              selectedProject = newValue;
                              selectedLocation = null;
                              locations = [];
                            });
                            fetchLocations(newValue!);
                          },
                        ),
                      ],
                      if (selectedProject != null && locations.isNotEmpty) ...[
                        _buildLabel('Location'),
                        _buildCircularDropdown(
                          hint: "Select Location",
                          value: selectedLocation,
                          items: locations.map((location) {
                            return DropdownMenuItem<String>(
                              value: location['name']?.toString(),
                              child: Text(location['name'] ?? 'Unknown'),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setState(() {
                              selectedLocation = newValue;
                            });
                          },
                        ),
                        SizedBox(height: 20.0),
                        Center(
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.8, // Adjust button width
                            padding: EdgeInsets.symmetric(vertical: 10.0),
                            child: ElevatedButton(
                              onPressed: () {
                                if (selectedLocation != null &&
                                    selectedClient != null &&
                                    selectedProject != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TeamAttendanceReport(
                                        clientId: selectedClient!,
                                        companyId: companyId!,
                                        projectId: selectedProject!,
                                        empCode: empCode!,
                                        locationId: selectedLocation!,
                                      ),
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 15.0), // Adjust button padding
                                backgroundColor: Colors.red,
                                elevation: 1, // No shadow
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                  side: BorderSide(width: 2.0, color: Colors.black), // Border
                                ),
                              ),
                              child: Text(
                                'Confirm',
                                style: TextStyle(
                                  fontSize: 18.0,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Text(
        text,
        style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildCircularDropdown({
    required String hint,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10.0),
      padding: EdgeInsets.symmetric(horizontal: 20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30.0),
        border: Border.all(color: Colors.grey),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          hint: Text(hint),
          value: value,
          items: items,
          onChanged: onChanged,
          isExpanded: true,
        ),
      ),
    );
  }
}
