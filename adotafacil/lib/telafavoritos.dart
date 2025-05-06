import 'package:flutter/material.dart';
import 'package:adotafacil/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'telaanimalpublicado.dart';
import 'animal_grid_card.dart';

class TelaFavoritos extends StatefulWidget {
  const TelaFavoritos({Key? key}) : super(key: key);

  @override
  State<TelaFavoritos> createState() => _TelaFavoritosState();
}

class _TelaFavoritosState extends State<TelaFavoritos> {
  List<dynamic> _favoritedAnimais = [];
  bool _isLoading = true;
  String? _errorMessage;
  int? _loggedInUserId;

  @override
  void initState() {
    super.initState();
    _loadUserIdAndFetchFavorites();
  }

  @override
  void dispose() {
     super.dispose();
  }


  Future<void> _loadUserIdAndFetchFavorites() async {
     SharedPreferences prefs = await SharedPreferences.getInstance();
     _loggedInUserId = prefs.getInt('id_usuario');

     if (_loggedInUserId != null) {
        if(mounted) {
            _fetchFavoritedAnimals();
        }
     } else {
        if (!mounted) return;
        setState(() {
           _isLoading = false;
           _errorMessage = 'Faça login para ver seus animais favoritos.';
           _favoritedAnimais = [];
        });
     }
  }

  Future<void> _fetchFavoritedAnimals() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (_loggedInUserId == null) {
       if (!mounted) return;
        setState(() {
           _isLoading = false;
           _errorMessage = 'ID do usuário não disponível.';
           _favoritedAnimais = [];
        });
        return;
    }

    try {
      // CORRIGIDO: Alterada a URL para o novo caminho da rota de favoritos
      var uri = Uri.parse('${ApiConfig.baseUrl}/api/animais/favoritos/usuario/$_loggedInUserId');

      var response = await http.get(uri);

      if (!mounted) return;

      if (response.statusCode == 200) {
        List<dynamic> animaisData = jsonDecode(response.body);
        setState(() {
          _favoritedAnimais = animaisData;
          _isLoading = false;
        });
      } else if (response.statusCode == 404) {
         if (!mounted) return;
          setState(() {
             _isLoading = false;
             _favoritedAnimais = [];
             _errorMessage = 'Nenhum animal favorito encontrado.';
          });
      }
      else {
        String message = 'Erro ao carregar favoritos. Status: ${response.statusCode}';
         try {
           final errorData = jsonDecode(response.body);
           if (errorData != null && errorData['message'] != null) {
             message = errorData['message'];
           }
         } catch (e) { /* ignore */ }
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = message;
           _favoritedAnimais = [];
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erro de comunicação ao carregar favoritos.';
        _favoritedAnimais = [];
      });
    }
  }

  void _navigateToAnimalDetail(int animalId) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TelaAnimalPublicado(idAnimal: animalId),
        ),
      ).then((_) {
         // Recarregar a lista de favoritos ao voltar da tela de detalhes
         _loadUserIdAndFetchFavorites();
      });
  }

  // Remover animal da lista local se for desfavoritado
  void _removeAnimalFromFavoritesList(int animalId, bool isFavorited) {
      if (!isFavorited) {
          setState(() {
              _favoritedAnimais.removeWhere((animal) => animal['id'] == animalId);
          });
      }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Meus Favoritos", style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.purple),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: _isLoading && _favoritedAnimais.isEmpty && _errorMessage == null
                  ? const Center(child: CircularProgressIndicator(color: Colors.purple))
                  : _errorMessage != null
                      ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
                      : _favoritedAnimais.isEmpty
                          ? Center(child: Text('Você ainda não adicionou nenhum animal aos favoritos.', style: TextStyle(color: Colors.grey[600])))
                          : GridView.builder(
                                shrinkWrap: true,
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.8,
                                ),
                                itemCount: _favoritedAnimais.length,
                                itemBuilder: (context, index) {
                                   final animal = _favoritedAnimais[index];
                                   return AnimalGridCard(
                                      animalData: animal,
                                      initialIsFavorited: true, // Sempre true na tela de favoritos
                                      onTap: () => _navigateToAnimalDetail(animal['id']),
                                      onFavoriteChanged: _removeAnimalFromFavoritesList, // Callback para remover da lista
                                   );
                                },
                              ),
            ),
          ],
        ),
      ),
    );
  }
}