import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField({super.key, this.label});
  final String? label;
  @override
  Widget build(BuildContext context) =>
      TextField(decoration: InputDecoration(labelText: label));
}
