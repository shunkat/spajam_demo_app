import 'package:flutter/material.dart';

class CommonLabel extends StatelessWidget {
  String text;
  CommonLabel({
    required this.text,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: const Color.fromARGB(255, 199, 182, 28),
      ),
    );
  }
}
