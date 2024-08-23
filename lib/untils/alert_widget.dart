import 'package:flutter/material.dart';

class CustomAlert extends StatelessWidget {
  final String message;
  final VoidCallback onDismissed;

  const CustomAlert({
    Key? key,
    required this.message,
    required this.onDismissed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, style: const TextStyle(color: Colors.black)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: onDismissed,
                child: const Text('OK'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void showCustomAlert(BuildContext context, String message) {
  OverlayEntry? overlayEntry;
  overlayEntry = OverlayEntry(
    builder: (context) {
      return CustomAlert(
        message: message,
        onDismissed: () {
          overlayEntry?.remove();
        },
      );
    },
  );

  Overlay.of(context)?.insert(overlayEntry);


}