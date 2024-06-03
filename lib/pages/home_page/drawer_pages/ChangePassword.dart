import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Changepassword extends StatefulWidget {
  const Changepassword({Key? key});

  @override
  State<Changepassword> createState() => _ChangepasswordState();
}

class _ChangepasswordState extends State<Changepassword> {
  bool _isObscureOldPassword = true;
  bool _isObscureNewPassword = true;
  bool _isObscureConfirmPassword = true;

  void _toggleOldPasswordVisibility() {
    setState(() {
      _isObscureOldPassword = !_isObscureOldPassword;
    });
  }

  void _toggleNewPasswordVisibility() {
    setState(() {
      _isObscureNewPassword = !_isObscureNewPassword;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _isObscureConfirmPassword = !_isObscureConfirmPassword;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Change Password",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.pink.shade800,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo
            Padding(

              padding: const EdgeInsets.all(16.0),
              child: Image.asset(
                'assets/images/zarvis.png', // Replace with your logo asset
                width: 150.w,
                height: 150.h,
              ),
            ),
            // Old Password TextField
            Padding(

              padding:
              EdgeInsets.symmetric(horizontal: 16.0),

              child: TextField(
                obscureText: _isObscureOldPassword,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Old Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isObscureOldPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: _toggleOldPasswordVisibility,
                  ),
                ),
              ),
            ),
            SizedBox(height: 10.h,),
            // New Password TextField
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                obscureText: _isObscureNewPassword,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'New Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isObscureNewPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: _toggleNewPasswordVisibility,
                  ),
                ),
              ),
            ),
            SizedBox(height: 10.h,),
            // Confirm New Password TextField
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                obscureText: _isObscureConfirmPassword,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Confirm New Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isObscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: _toggleConfirmPasswordVisibility,
                  ),
                ),
              ),
            ),
            // Submit Button
            SizedBox(height: 12.h,),
            ElevatedButton(
              onPressed: (){},
              child: Text(
                "Submit",
                style: TextStyle(
                  fontSize: 18.sp,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink.shade800,
                padding: EdgeInsets.symmetric(
                  horizontal: 130.w,
                  vertical: 10.h,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5.0),
                ),
              ),
            ),


          ],
        ),
      ),
    );
  }
}
