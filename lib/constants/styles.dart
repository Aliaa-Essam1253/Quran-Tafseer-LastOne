import 'package:flutter/material.dart';

ButtonStyle elevatedButtonStyle(Color color) {
  return ElevatedButton.styleFrom(
    backgroundColor: color,
    minimumSize: const Size(double.infinity, 50),
  );
}
