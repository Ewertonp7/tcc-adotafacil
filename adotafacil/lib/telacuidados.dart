import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class telacuidados extends StatelessWidget {
  void _abrirGoogleBusca() async {
    final query = 'Como cuidar do meu animal?';
    final url = 'https://www.google.com/search?q=${Uri.encodeComponent(query)}';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Não foi possível abrir o navegador.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cuidados', style: TextStyle(fontWeight: FontWeight.bold,
              color: Colors.pink)),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.pink[700]),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  _buildSection(
                    title: 'Higiene',
                    content:
                        'Após o primeiro banho, recomenda-se que o animal tome banho mensalmente, conforme sua condição e estilo de vida. A higiene ajuda a prevenir alergias, infecções e parasitas. Animais que vivem fora de casa podem precisar de mais banhos, enquanto os de ambiente interno podem espaçar mais. Também é importante escovar o pelo, limpar as orelhas e cortar as unhas.',
                  ),
                  _buildSection(
                    title: 'Alimentação',
                    content:
                        'Filhotes de dois a três meses devem ser alimentados quatro vezes ao dia para garantir um bom desenvolvimento. De quatro a seis meses, passam a comer três vezes ao dia, e após um ano, duas vezes ao dia para manter a saúde.',
                  ),
                  _buildSection(
                    title: 'Vacinas',
                    content:
                        'A cada 2 ou 3 semanas até ele completar 4 meses de idade. Eles são posteriormente revacinados anualmente.',
                  ),
                  const SizedBox(height: 15),
                  Text(
                    'Deseja ter mais informações sobre o cuidado do seu amiguinho? Clique no botão abaixo',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _abrirGoogleBusca,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 0, 37, 116),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Mais informações'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: RichText(
        text: TextSpan(
          style:
              const TextStyle(color: Colors.black, fontSize: 17, height: 1.5),
          children: [
            TextSpan(
              text: '$title\n',
              style: TextStyle(
                color: Colors.pink[700],
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(text: content),
          ],
        ),
      ),
    );
  }
}
