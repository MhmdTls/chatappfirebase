import 'package:flutter/material.dart';

class MyButton extends StatelessWidget {
  final void Function()? onTap;
  final String text;
  const MyButton({super.key, required this.onTap, required this.text, });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(

      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
        gradient: LinearGradient(
         colors: [Color(0xFF00B4D8), Color(0xFF00E0C6)]),
          borderRadius: BorderRadius.circular(10),

        ),

        child: Center(
          child: Text(text,
          style: const TextStyle( color: Colors.white,
          fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
          ),


        ),

      ),
    );
  }
}
