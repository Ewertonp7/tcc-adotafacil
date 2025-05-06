import 'package:flutter/material.dart';
import 'package:adotafacil/api_config.dart';

class AnimalDetalhes extends StatelessWidget {
  final String nome;
  final String imagem;
  final String idade;
  final String peso;
  final String sexo;
  final String descricao;

  AnimalDetalhes({
    required this.nome,
    required this.imagem,
    required this.idade,
    required this.peso,
    required this.sexo,
    required this.descricao,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0, // Removi a elevação
        leading: IconButton(
          icon: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 221, 220, 221),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.arrow_back,
                color: const Color.fromARGB(255, 0, 37, 116)),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              imagem,
              height: 220, // Ajuste a altura se necessário
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            SizedBox(height: 15),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                nome,
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(255, 0, 37, 116)!),
              ),
            ),
            SizedBox(height: 5), // Espaçamento menor
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InfoCard(label: "Idade", valor: idade),
                  InfoCard(label: "Peso", valor: peso),
                  InfoCard(label: "Sexo", valor: sexo),
                ],
              ),
            ),
            SizedBox(height: 10), // Espaçamento menor
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Informações de $nome",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(255, 0, 37, 116)!),
              ),
            ),
            SizedBox(height: 10),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                descricao,
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ),
            SizedBox(height: 20), // Espaçamento menor
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton(
                onPressed: () {
                  // Ação ao clicar no botão
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 0, 37, 116),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  minimumSize: Size(double.infinity, 50),
                ),
                child: Text(
                  "Entrar em Contato",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
            SizedBox(height: 15),
          ],
        ),
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final String label;
  final String valor;

  InfoCard({required this.label, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 18),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 221, 220, 221),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center, // Centralizar verticalmente
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 15, color: const Color.fromARGB(255, 0, 37, 116))),
          Text(valor,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
