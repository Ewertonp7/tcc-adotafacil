import 'package:flutter/material.dart';
import 'telaacesso.dart';
import 'telacadastro.dart';

void main() {
  runApp(const AdotaFacilApp());
}

class AdotaFacilApp extends StatelessWidget {
  const AdotaFacilApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const AdotaFacilScreen(),
    );
  }
}

class AdotaFacilScreen extends StatelessWidget {
  const AdotaFacilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // Permite que a tela "suba" com o teclado
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.4,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(100),
                    bottomRight: Radius.circular(100),
                  ),
                  image: DecorationImage(
                    image: AssetImage('assets/images/doglogin.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Column(
                  children: [
                    const SizedBox(height: 30),
                    RichText(
                      text: const TextSpan(
                        style:
                            TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                        children: [
                          TextSpan(
                              text: 'Adota',
                              style: TextStyle(color: Colors.red)),
                          TextSpan(
                              text: 'Fácil',
                              style: TextStyle(
                                  color: Color.fromARGB(255, 0, 37, 116))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Bem-vindo!\nFaça login ou registre-se para adotar seu novo amigo peludo.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 0, 37, 116),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 50, vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const TelaAcesso()),
                        );
                      },
                      child: const Text(
                        'INICIAR SESSÃO',
                        style: TextStyle(fontSize: 22, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 50, vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        side: const BorderSide(
                            color: Color.fromARGB(255, 0, 37, 116)),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CadastroScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'CRIAR CONTA',
                        style: TextStyle(
                            fontSize: 22,
                            color: Color.fromARGB(255, 0, 37, 116)),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}