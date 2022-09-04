import 'package:flutter/material.dart';

class CommonButton extends StatelessWidget {
  String title;
  VoidCallback onPressed;
  CommonButton({required this.title, required this.onPressed, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        child: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 199, 182, 28),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(
            vertical: 14,
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }
}
