import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'api_config.dart';
import 'telaanimalpublicado.dart';

class TelaMeusAnimais extends StatefulWidget {
  const TelaMeusAnimais({Key? key}) : super(key: key);

  @override
  _TelaMeusAnimaisState createState() => _TelaMeusAnimaisState();
}

class _TelaMeusAnimaisState extends State<TelaMeusAnimais> {
  List<dynamic> _meusAnimais = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isFetching = false;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _fetchMeusAnimais();
  }

  Future<void> _fetchMeusAnimais() async {
    if (!mounted || _isFetching) return;

    _isFetching = true;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int? idUsuario = prefs.getInt('id_usuario');

      if (idUsuario == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Usuário não logado.';
        });
        return;
      }

      var uri = Uri.parse('${ApiConfig.baseUrl}/api/animais/usuario/$idUsuario');
      var response = await http.get(uri);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _meusAnimais = data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _meusAnimais = [];
          _errorMessage = 'Erro ao carregar seus anúncios. Código: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _meusAnimais = [];
        _errorMessage = 'Erro de comunicação ao carregar anúncios.';
        _isLoading = false;
      });
    } finally {
      _isFetching = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Meus Anúncios', style: TextStyle(color: Colors.pink)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.pink),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading && _meusAnimais.isEmpty && _errorMessage == null
          ? const Center(child: CircularProgressIndicator(color: Colors.purple))
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: TextStyle(color: Colors.red)))
              : _meusAnimais.isEmpty
                  ? Center(child: Text('Você ainda não publicou nenhum animal.', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _meusAnimais.length,
                      itemBuilder: (context, index) {
                        final animal = _meusAnimais[index];
                        final int idAnimal = animal['id'];
                        final String nomeAnimal = animal['nome'] ?? 'Sem Nome';
                        final List<String> imagensUrls = List<String>.from(animal['imagens'] ?? []);
                        final String primeiraImagemUrl = imagensUrls.isNotEmpty ? imagensUrls.first : '';

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () {
                              if (_isNavigating) return;

                              setState(() {
                                _isNavigating = true;
                              });

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TelaAnimalPublicado(idAnimal: idAnimal),
                                ),
                              ).then((_) async {
                                if (mounted) {
                                  setState(() {
                                    _isNavigating = false;
                                  });
                                  await _fetchMeusAnimais(); // <- agora com await
                                }
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 25,
                                    backgroundColor: Colors.grey.shade300,
                                    backgroundImage: primeiraImagemUrl.isNotEmpty
                                        ? NetworkImage(primeiraImagemUrl)
                                        : null,
                                    child: primeiraImagemUrl.isEmpty
                                        ? Icon(Icons.pets, size: 25, color: Colors.grey[600])
                                        : null,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          nomeAnimal,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.purple.shade800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}