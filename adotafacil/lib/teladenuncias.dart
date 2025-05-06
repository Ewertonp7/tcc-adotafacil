import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const AdotaFacilApp());
}

class AdotaFacilApp extends StatelessWidget {
  const AdotaFacilApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const TelaDenuncias(),
    );
  }
}

class TelaDenuncias extends StatelessWidget {
  const TelaDenuncias({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(color: Colors.pink),
        title: const Text('Denúncias', style: TextStyle(fontWeight: FontWeight.bold,
              color: Colors.pink)),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ajudamos a salvar vidas',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.pink,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Na AdotaFácil repudiamos veementemente os maus tratos e qualquer tipo de dano aos animais, por isso disponibilizamos este espaço para ajudar aqueles que não conseguem se defender.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            ReportCard(
              imageUrl: 'assets/images/doglogin.png',
              title: 'Animal abandonado',
            ),
            const SizedBox(height: 20),
            ReportCard(
              imageUrl: 'assets/images/gato.png',
              title: 'Maltrato animal',
            ),
          ],
        ),
      ),
    );
  }
}

class ReportCard extends StatelessWidget {
  final String imageUrl;
  final String title;

  const ReportCard({
    Key? key,
    required this.imageUrl,
    required this.title,
  }) : super(key: key);

  void _showCallDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disque Denúncia'),
        content: const Text('Deseja ligar para o número 181?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final Uri launchUri = Uri(scheme: 'tel', path: '181');
              if (await canLaunchUrl(launchUri)) {
                await launchUrl(launchUri);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Não foi possível abrir o discador.'),
                  ),
                );
              }
            },
            child: const Text('Ligar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                imageUrl,
                width: 140, // Atualizado para 140
                height: 140, // Atualizado para 140
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showCallDialog(context),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(150, 48), // Botão maior
                      backgroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    icon:
                        const Icon(Icons.phone, size: 22, color: Colors.white),
                    label: const Text(
                      'Reportar',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
