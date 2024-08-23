import 'dart:convert';
// import 'dart:nativewrappers/_internal/vm/lib/convert_patch.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Example extends StatefulWidget {
  const Example({super.key});
  @override
  State<Example> createState() => _ExampleState();
}

class _ExampleState extends State<Example> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    response();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(''),
      ),
    );
  }

  Future response() async {
    String baseUrl = "http://35.154.148.75/zarvis/api/v3/register";
    var response_data = await http.post(Uri.parse(baseUrl), body: {
      'emp_code': '4812',
      'device_id': '12345679',
      'emp_id': 'E4876',
      'shift_code': '1',
      'first_name': 'Priyanshu'
    });
    if(response_data.statusCode == 200){
      var mdata = jsonDecode(response_data.body);
      print(mdata);
    }
    else{
      print('error');
    }


  }
}
