import 'package:flutter/material.dart';

class CustomNumberField extends StatelessWidget {
  const CustomNumberField({super.key});
  @override
  Widget build(BuildContext context) =>
      const TextField(keyboardType: TextInputType.number);
}
