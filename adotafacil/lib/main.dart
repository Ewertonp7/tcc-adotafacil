import 'package:flutter/material.dart';
import 'telalogin.dart'; // Importe o arquivo telalogin.dart

void main() {
  runApp(const AdotaFacilApp());
}

class AdotaFacilApp extends StatelessWidget {
  const AdotaFacilApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AdotaFacilScreen(), // Use AdotaFacilScreen como a tela inicial
    );
  }
}