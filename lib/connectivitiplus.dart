import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Connectivitiplus extends GetxController {
  Connectivity _connectivity = Connectivity();

  @override
  void onInit() {
    super.onInit();
    _connectivity.onConnectivityChanged.listen(checkInternetConnectivity
    );
  }

  void showNoInternetSnackbar() {
    Get.snackbar(
      "No Internet Connection",
      "Please connect to the internet",
      icon: Icon(Icons.wifi_off, color: Colors.red, size: 30),
      isDismissible: true,
      duration: Duration(days: 1),
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.black.withOpacity(0.5),
      colorText: Colors.white,
    );
  }


  void checkInternetConnectivity(List<ConnectivityResult> results) {
    final result = results.last; // Get the latest connectivity result
    if (result == ConnectivityResult.none) {
      showNoInternetSnackbar();
    }
  }
}
