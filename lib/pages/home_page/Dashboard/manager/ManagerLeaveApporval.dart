import 'package:flutter/material.dart';

class Managerleaveapporval extends StatefulWidget {
  const Managerleaveapporval({Key? key}) : super(key: key);

  @override
  State<Managerleaveapporval> createState() => _ManagerleaveapporvalState();
}

class _ManagerleaveapporvalState extends State<Managerleaveapporval> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(top: true,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "Manager Leave Approval",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildInfoContainer("Pending ", "0", Colors.blueAccent),
                  _buildInfoContainer("Approved", "0", Colors.green),
                  _buildInfoContainer("Rejected", "0", Colors.red),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: 0, // No data for now
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                    child: Container(
                      padding: EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '', // Empty string for now
                                style: TextStyle(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4.0),
                              Text(
                                '', // Empty string for now
                                style: TextStyle(
                                  fontSize: 16.0,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Text(
                                '', // Empty string for now
                                style: TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.call, color: Colors.green),
                                onPressed: () {
                                  // Empty callback for now
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoContainer(String title, String value, Color color) {
    return Container(
      color: color,
      width: 130,
      height: 80,
      child: Center(
        child: Text(
          "$title\n$value",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
