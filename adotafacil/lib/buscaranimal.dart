import 'package:flutter/material.dart';
import 'package:adotafacil/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'animal_grid_card.dart';
import 'telaanimalpublicado.dart';
import 'image_viewer_screen.dart';

class BuscarAnimal extends StatefulWidget {
const BuscarAnimal({Key? key}) : super(key: key);

@override
_BuscarAnimalState createState() => _BuscarAnimalState();
}

class _BuscarAnimalState extends State<BuscarAnimal> {
List<dynamic> _animais = [];
bool _isLoading = true;
String? _errorMessage;
int? _loggedInUserId;

final TextEditingController _searchController = TextEditingController();
final TextEditingController _filterRacaController = TextEditingController();
final TextEditingController _filterNomeController = TextEditingController();
final TextEditingController _filterMinAgeController = TextEditingController();
final TextEditingController _filterMaxAgeController = TextEditingController();
String? _filterSelectedSex;
String? _filterSelectedSize;

Map<String, dynamic> _currentFilters = {};

  bool _isFetching = false;
  bool _isNavigating = false; // Controla se está navegando


@override
void initState() {
 super.initState();
   print('DEBUG(BuscarAnimal): initState iniciado.');
 _loadUserIdAndFetchAnimals();
}

@override
void dispose() {
   print('DEBUG(BuscarAnimal): dispose iniciado.');
 _searchController.dispose();
 _filterRacaController.dispose();
 _filterNomeController.dispose();
 _filterMinAgeController.dispose();
 _filterMaxAgeController.dispose();
 super.dispose();
}

 Future<void> _loadUserIdAndFetchAnimals() async {
    print('DEBUG(BuscarAnimal): _loadUserIdAndFetchAnimals iniciado.');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _loggedInUserId = prefs.getInt('id_usuario');
    print('DEBUG(BuscarAnimal): Usuário logado ID: $_loggedInUserId');
    if(mounted) {
        _fetchAnimals();
    }
    print('DEBUG(BuscarAnimal): _loadUserIdAndFetchAnimals finalizado.');
 }


// Busca e filtra animais, refatorado para single setState
Future<void> _fetchAnimals({Map<String, dynamic>? filters, String? searchTerm}) async {
   if (_isFetching) {
       print('DEBUG(BuscarAnimal): Fetch already in progress. Returning.');
       return;
   }
   _isFetching = true;
   print('DEBUG(BuscarAnimal): _fetchAnimals iniciado. Filters: $filters, SearchTerm: $searchTerm');

   List<dynamic>? nextAnimais;
   String? nextErrorMessage;

   try {
     if (mounted) {
       setState(() {
         print('DEBUG(BuscarAnimal): setState (início _fetchAnimals - isLoading=true)');
         _isLoading = true;
         _errorMessage = null;
         if (filters != null) {
           _currentFilters = filters;
         } else if (searchTerm != null) {
           _currentFilters = {'busca': searchTerm};
         }
       });
     }


  var uri = Uri.parse('${ApiConfig.baseUrl}/api/animais');

 Map<String, dynamic> queryParams = Map.from(_currentFilters);
 if (_loggedInUserId != null) {
  queryParams['id_usuario'] = _loggedInUserId.toString();
 }
 uri = uri.replace(queryParameters: queryParams);

 print('DEBUG(BuscarAnimal): Requisitando animais: $uri');

 var response = await http.get(uri);

 if (!mounted) {
       print('DEBUG(BuscarAnimal): Widget desmontado após requisição.');
       return; // Parar se o widget não estiver mais ativo
    }

    print('DEBUG(BuscarAnimal): Resposta recebida. Status: ${response.statusCode}');

 if (response.statusCode == 200) {
   nextAnimais = jsonDecode(response.body);
     print('DEBUG(BuscarAnimal): Animais carregados com sucesso. Itens: ${nextAnimais!.length}');
     nextErrorMessage = null;
 } else {
     print('DEBUG(BuscarAnimal): Erro no backend. Status: ${response.statusCode}');
   String message = 'Erro ao carregar animais. Status: ${response.statusCode}';
  try {
   final errorData = jsonDecode(response.body);
   if (errorData != null && errorData['message'] != null) {
   message = errorData['message'];
   }
  } catch (e) { /* ignore */ }
     nextErrorMessage = message;
     nextAnimais = [];
    print('DEBUG(BuscarAnimal): _fetchAnimals - Erro backend finalizado.');
 }
 } catch (e) {
 print('DEBUG(BuscarAnimal): Erro na comunicação ao buscar animais: $e');
 if (!mounted) return;
    nextErrorMessage = 'Erro de comunicação ao carregar animais.';
    nextAnimais = [];
    print('DEBUG(BuscarAnimal): _fetchAnimals - Erro comunicação finalizado.');
 } finally {
     _isFetching = false;
     if (mounted) {
        setState(() {
           print('DEBUG(BuscarAnimal): setState (finally _fetchAnimals)');
           _isLoading = false;
           if (nextAnimais != null) {
              _animais = nextAnimais;
           }
           _errorMessage = nextErrorMessage;
        });
     }
     print('DEBUG(BuscarAnimal): _fetchAnimals finalizado (finally).');
  }
   print('DEBUG(BuscarAnimal): _fetchAnimals finalizado (fim do método).');
}


void _showFilterDialog() {
   print('DEBUG(BuscarAnimal): _showFilterDialog iniciado.');
 showDialog(
 context: context,
 builder: (BuildContext context) {
  return AlertDialog(
  title: const Text("Filtrar Animais"),
  content: SingleChildScrollView(
   child: Column(
   mainAxisSize: MainAxisSize.min,
   children: [
    TextField(controller: _filterRacaController, decoration: const InputDecoration(labelText: "Raça")),
    TextField(controller: _filterNomeController, decoration: const InputDecoration(labelText: "Nome")),
    Row(children: [
     Expanded(child: TextField(controller: _filterMinAgeController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Idade mínima"))),
     const SizedBox(width: 10),
     Expanded(child: TextField(controller: _filterMaxAgeController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Idade máxima"))),
    ],
    ),
    DropdownButtonFormField<String>(
    decoration: const InputDecoration(labelText: "Sexo"), value: _filterSelectedSex,
    items: const [
     DropdownMenuItem(value: null, child: Text("Qualquer")),
     DropdownMenuItem(value: "Macho", child: Text("Macho")),
     DropdownMenuItem(value: "Fêmea", child: Text("Fêmea")),
    ],
    onChanged: (value) { setState(() { _filterSelectedSex = value; }); },
    ),
    DropdownButtonFormField<String>(
    decoration: const InputDecoration(labelText: "Porte"), value: _filterSelectedSize,
    items: const [
     DropdownMenuItem(value: null, child: Text("Qualquer")),
     DropdownMenuItem(value: "Pequeno", child: Text("Pequeno")),
     DropdownMenuItem(value: "Médio", child: Text("Médio")),
     DropdownMenuItem(value: "Grande", child: Text("Grande")),
    ],
    onChanged: (value) { setState(() { _filterSelectedSize = value; }); },
    ),
   ],
   ),
  ),
  actions: [
   TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Cancelar")),
   TextButton(
   onPressed: () {
    Map<String, dynamic> filters = {};
    if (_filterRacaController.text.isNotEmpty) filters['raca'] = _filterRacaController.text;
    if (_filterNomeController.text.isNotEmpty) filters['nome'] = _filterNomeController.text;
    if (_filterMinAgeController.text.isNotEmpty) { int? minAge = int.tryParse(_filterMinAgeController.text); if (minAge != null) filters['min_idade'] = minAge.toString(); }
    if (_filterMaxAgeController.text.isNotEmpty) { int? maxAge = int.tryParse(_filterMaxAgeController.text); if (maxAge != null) filters['max_idade'] = maxAge.toString(); }
    if (_filterSelectedSex != null) filters['sexo'] = _filterSelectedSex;
    if (_filterSelectedSize != null) filters['porte'] = _filterSelectedSize;
        print('DEBUG(BuscarAnimal): Aplicando filtros e buscando animais.');
    _fetchAnimals(filters: filters);
    Navigator.of(context).pop();
   },
   child: const Text("Filtrar"),
   ),
  ],
  );
 },
 ).then((_) {
    print('DEBUG(BuscarAnimal): Dialog de filtro fechado.');
 });
   print('DEBUG(BuscarAnimal): _showFilterDialog finalizado.');
}

void _performSearch(String searchTerm) {
    print('DEBUG(BuscarAnimal): _performSearch iniciado com termo: $searchTerm');
   _fetchAnimals(searchTerm: searchTerm);
     print('DEBUG(BuscarAnimal): _performSearch finalizado.');
}

 // Atualizar o estado de um animal na lista localmente
 void _updateAnimalFavoriteStatus(int animalId, bool isFavorited) {
    print('DEBUG(BuscarAnimal): _updateAnimalFavoriteStatus para animal $animalId, favorited: $isFavorited');
    final index = _animais.indexWhere((animal) => animal['id'] == animalId);
    if (index != -1) {
       setState(() {
         print('DEBUG(BuscarAnimal): setState (_updateAnimalFavoriteStatus)');
         _animais[index]['is_favorited'] = isFavorited;
       });
       print('DEBUG(BuscarAnimal): Status de favorito atualizado localmente para animal $animalId: $isFavorited');
    } else {
        print('DEBUG(BuscarAnimal): Animal $animalId não encontrado na lista local para atualizar.');
    }
     print('DEBUG(BuscarAnimal): _updateAnimalFavoriteStatus finalizado.');
 }


@override
Widget build(BuildContext context) {
   print('DEBUG(BuscarAnimal): build iniciado. Itens na lista: ${_animais.length}');
 return Scaffold(
 backgroundColor: Colors.white,
 appBar: AppBar(
  title: const Text(
   "AdotaFácil",
   style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold)
  ),
  backgroundColor: Colors.white,
  elevation: 0,
  centerTitle: true,
  iconTheme: const IconThemeData(color: Colors.purple),
 ),
 body: Padding(
  padding: const EdgeInsets.all(16.0),
  child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
   Row(
   children: [
    Expanded(
    child: TextField(
     controller: _searchController,
     onSubmitted: _performSearch,
     onChanged: (value) {
      if (value.isEmpty && (_currentFilters.containsKey('busca') || _searchController.text.isNotEmpty)) {
                 print('DEBUG(BuscarAnimal): Texto de busca apagado, buscando sem termo.');
                 _performSearch('');
             }
     },
     decoration: InputDecoration(
     hintText: "Buscar animal (nome ou raça)",
     prefixIcon: const Icon(Icons.search),
     border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: BorderSide.none,
     ),
     filled: true,
     fillColor: Colors.grey[200],
     contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
     ),
    ),
    ),
    const SizedBox(width: 10),
    IconButton(
    icon: const Icon(Icons.filter_list, color: Colors.purple),
    onPressed: _showFilterDialog,
    ),
   ],
   ),
   const SizedBox(height: 20),

   Expanded(
   child: _isLoading && _animais.isEmpty && _errorMessage == null
    ? const Center(child: CircularProgressIndicator(color: Colors.purple))
    : _errorMessage != null
     ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
     : _animais.isEmpty
      ? Center(child: Text(_currentFilters.isNotEmpty ? 'Nenhum animal encontrado com os filtros aplicados.' : 'Nenhum animal disponível para adoção no momento.', style: TextStyle(color: Colors.grey[600])))
      : GridView.builder(
       shrinkWrap: true,
       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.8,
       ),
       itemCount: _animais.length,
       itemBuilder: (context, index) {
        final animal = _animais[index];
        return AnimalGridCard(
         animalData: animal,
         initialIsFavorited: animal['is_favorited'] ?? false,
         onTap: () {
                       // Adicionado check _isNavigating para evitar cliques múltiplos
                      if (_isNavigating) {
                         print('DEBUG(BuscarAnimal): Navegação já em andamento, ignorando clique.');
                         return;
                      }
                      setState(() {
                         print('DEBUG(BuscarAnimal): setState (onTap - _isNavigating=true)');
                         _isNavigating = true; // Definir flag ao iniciar navegação
                      });

                      print('DEBUG(BuscarAnimal): Item ${index} (${animal['id']}) clicado. Navegando para detalhes.');
         Navigator.push(
          context,
          MaterialPageRoute(
          builder: (context) => TelaAnimalPublicado(idAnimal: animal['id']),
          ),
         ).then((_) {
                       print('DEBUG(BuscarAnimal): Retornou da TelaAnimalPublicado.');
                       // Resetar flag de navegação ao retornar
                       if (mounted) {
                           setState(() {
                               print('DEBUG(BuscarAnimal): setState (then - _isNavigating=false)');
                               _isNavigating = false;
                           });
                       }
                       // Não recarregar lista inteira aqui, o callback do card já atualiza o item individual
                   });
         },
         onFavoriteChanged: _updateAnimalFavoriteStatus,
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