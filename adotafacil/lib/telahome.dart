import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'buscaranimal.dart';
import 'telaperfil.dart';
import 'telapubli.dart';
import 'teladenuncias.dart';
import 'telameusanimais.dart';
import 'telafavoritos.dart';
import 'telacuidados.dart';
import 'telaacesso.dart';

class TelaHome extends StatefulWidget {
  const TelaHome({super.key});

  @override
  State<TelaHome> createState() => _TelaHomeState();
}

class _TelaHomeState extends State<TelaHome> {
  int _indiceAtual = 0;

  void _mudarTela(int index) {
    // Lógica para evitar navegação desnecessária se já estiver na tela home
    if (index == 0 && _indiceAtual == 0) return;

    setState(() {
      _indiceAtual = index;
    });

    // Navega para outras telas, mas reseta o índice para 0 ao voltar
    // para que a aba "Início" fique selecionada corretamente
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => telacuidados()),
      ).then((_) => setState(() => _indiceAtual = 0)); // Reseta o índice ao voltar
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const TelaDenuncias()),
      ).then((_) => setState(() => _indiceAtual = 0)); // Reseta o índice ao voltar
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const TelaPerfil()),
      ).then((_) => setState(() => _indiceAtual = 0)); // Reseta o índice ao voltar
    }
  }

  // Função para mostrar o diálogo de confirmação e realizar o logoff se confirmado
  
  // Retorna 'false' para indicar que o WillPopScope NÃO deve realizar o pop padrão,
  // pois nós mesmos faremos a navegação (ou não faremos nada se o usuário cancelar).
  Future<bool> _onWillPop() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Impede fechar clicando fora
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar Saída'),
          content: const Text('Deseja realmente fazer logoff do aplicativo?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Não'),
              onPressed: () {
                Navigator.of(dialogContext).pop(false); // Retorna false = não sair
              },
            ),
            TextButton(
              child: const Text('Sim'),
              onPressed: () {
                // NÃO fazemos a navegação aqui dentro ainda
                Navigator.of(dialogContext).pop(true); // Retorna true = confirmar saída
              },
            ),
          ],
        );
      },
    );

    // Verifica o resultado do diálogo
    if (shouldLogout ?? false) { // Se o usuário confirmou (pressionou Sim)
      // 1. Executa a lógica de logout (igual à TelaPerfil)
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('id_usuario');
      debugPrint('🔑 ID do usuário removido das SharedPreferences na TelaHome.');

      // 2. Navega para TelaAcesso e remove todas as rotas anteriores
      if (mounted) { // Garante que o widget ainda está na árvore
         Navigator.pushAndRemoveUntil(
           context,
           MaterialPageRoute(builder: (context) => const TelaAcesso()),
           (Route<dynamic> route) => false, // Predicado que sempre retorna false remove todas as rotas
         );
         debugPrint('🔄 Navegado para TelaAcesso e pilha de rotas limpa a partir da TelaHome.');
      }
      // 3. Retorna false para o WillPopScope, pois já fizemos a navegação manualmente.
      return false;
    } else {
      // Se o usuário cancelou (pressionou Não ou fechou o diálogo),
      // retorna false para impedir o pop padrão e manter o usuário na TelaHome.
       debugPrint('❌ Logoff cancelado pelo usuário na TelaHome.');
      return false;
    }
  }


  @override
  Widget build(BuildContext context) {
    // Envolve o Scaffold com WillPopScope
    return WillPopScope(
      // onWillPop chama nossa função de confirmação/logout
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'AdotaFácil',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.pink,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
           // Remover o botão de voltar padrão da AppBar
          automaticallyImplyLeading: false,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Bem-Vindo ao nosso App!\nSelecione a opção que seja próxima ao que você deseja!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.purple.shade800,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const TelaMeusAnimais()),
                    ).then((_) => setState(() => _indiceAtual = 0)); // Reseta o índice
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        Icon(Icons.folder_shared_outlined,
                            size: 30, color: Colors.purple),
                        SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Meus Anúncios',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios,
                            size: 18, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  children: [
                    _buildAnimalButton(
                      context,
                      'Buscar Animais',
                      'assets/images/dog1.png',
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const BuscarAnimal()),
                        ).then((_) => setState(() => _indiceAtual = 0)); // Reseta o índice
                      },
                    ),
                    _buildAnimalButton(
                      context,
                      'Publicar Animal',
                      'assets/images/dog2.png',
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const TelaPubli()),
                        ).then((_) => setState(() => _indiceAtual = 0)); // Reseta o índice
                      },
                    ),
                    _buildAnimalButton(
                      context,
                      'Favoritos',
                      'assets/images/gato1.png',
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const TelaFavoritos()),
                        ).then((_) => setState(() => _indiceAtual = 0)); // Reseta o índice
                      },
                    ),
                    _buildAnimalButton(
                      context,
                      'Cuidados',
                      'assets/images/gato2.png',
                      () {
                         Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => telacuidados()),
                          ).then((_) => setState(() => _indiceAtual = 0)); // Reseta o índice
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _indiceAtual,
          selectedItemColor: Colors.pink,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          onTap: _mudarTela,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Início',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.pets),
              label: 'Cuidados',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.report),
              label: 'Reportar',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }

  // Função auxiliar _buildAnimalButton (sem alterações)
  Widget _buildAnimalButton(BuildContext context, String title,
      String imagePath, VoidCallback onPressed) {
    // ... (seu código do _buildAnimalButton aqui)
     return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 6,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(imagePath, fit: BoxFit.cover),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}