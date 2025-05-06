import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:adotafacil/api_config.dart';
import 'telaanimalpublicado.dart';
import 'dart:convert';

typedef OnFavoriteChanged = void Function(int animalId, bool isFavorited);

class AnimalGridCard extends StatefulWidget {
  final dynamic animalData;
  final VoidCallback? onTap;
  final bool initialIsFavorited;
  final OnFavoriteChanged? onFavoriteChanged;

  const AnimalGridCard({
    Key? key,
    required this.animalData,
    this.onTap,
    this.initialIsFavorited = false,
    this.onFavoriteChanged,
  }) : super(key: key);

  @override
  State<AnimalGridCard> createState() => _AnimalGridCardState();
}

class _AnimalGridCardState extends State<AnimalGridCard> {
  late bool _isFavorited;

  @override
  void initState() {
    super.initState();
    _isFavorited = widget.initialIsFavorited;
  }

  void _toggleFavorite() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? idUsuario = prefs.getInt('id_usuario');

    if (idUsuario == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Você precisa estar logado para favoritar animais.')),
      );
      return;
    }

    final int idAnimal = widget.animalData['id'];

    var uri = Uri.parse('${ApiConfig.baseUrl}/api/animais/$idAnimal/favoritar'); // CORRIGIDO: Adicionado /api/animais
    try {
      var response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idUsuario': idUsuario}),
      );

      if (!mounted) return;

      final responseData = jsonDecode(response.body);
      final bool backendIsFavorited = responseData['isFavorited'] ?? !_isFavorited;

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          _isFavorited = backendIsFavorited;
        });

        if (widget.onFavoriteChanged != null) {
           widget.onFavoriteChanged!(idAnimal, _isFavorited);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(backendIsFavorited ? 'Animal adicionado aos favoritos!' : 'Animal removido dos favoritos!')),
        );
      } else {
        String errorMessage = responseData != null && responseData['message'] != null
            ? responseData['message']
            : 'Erro ao atualizar favorito. Status: ${response.statusCode}';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro de comunicação ao favoritar.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final int idAnimal = widget.animalData['id'];
    final String nome = widget.animalData['nome'] ?? 'Sem Nome';
    final String raca = widget.animalData['raca'] ?? 'Sem Raça';
    final dynamic idadeData = widget.animalData['idade'];
    final String idade = idadeData != null ? '${idadeData.toString()} anos' : 'Idade N/A';
    final String sexo = widget.animalData['sexo'] ?? 'Macho';
    final List<String> imagensUrls = List<String>.from(widget.animalData['imagens'] ?? []);
    final String primeiraImagemUrl = imagensUrls.isNotEmpty ? imagensUrls.first : '';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: primeiraImagemUrl.isNotEmpty
                    ? Image.network(
                        primeiraImagemUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: double.infinity,
                            color: Colors.grey[200],
                            child: const Center(child: Icon(Icons.broken_image, size: 40, color: Colors.grey)),
                          );
                        },
                      )
                    : Container(
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: const Center(child: Icon(Icons.pets, size: 40, color: Colors.grey)),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nome, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18), overflow: TextOverflow.ellipsis),
                  Text('$raca, $idade', style: const TextStyle(color: Colors.grey, fontSize: 14), overflow: TextOverflow.ellipsis),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(sexo == 'Fêmea' ? Icons.female : Icons.male, color: sexo == 'Fêmea' ? Colors.pink : Colors.blue, size: 20),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          _isFavorited ? Icons.favorite : Icons.favorite_border,
                          color: _isFavorited ? Colors.red : Colors.grey,
                        ),
                        onPressed: _toggleFavorite,
                      ),
                    ],
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