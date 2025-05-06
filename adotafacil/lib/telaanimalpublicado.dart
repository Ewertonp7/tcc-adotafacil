import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:http/http.dart' as http;
import 'package:adotafacil/api_config.dart'; // Certifique-se que este import está correto
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'image_viewer_screen.dart'; // Certifique-se que este import está correto
import 'package:carousel_slider/carousel_slider.dart';
import 'package:url_launcher/url_launcher.dart';

class TelaAnimalPublicado extends StatefulWidget {
  final int idAnimal;

  const TelaAnimalPublicado({
    super.key,
    required this.idAnimal,
  });

  @override
  State<TelaAnimalPublicado> createState() => _TelaAnimalPublicadoState();
}

class _TelaAnimalPublicadoState extends State<TelaAnimalPublicado> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nomeController = TextEditingController();
  final _idadeController = TextEditingController();
  final _corController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _especieController = TextEditingController();
  final _racaController = TextEditingController();

  // State variables
  String _sexo = 'Macho';
  String _porte = 'Pequeno';
  int _idSituacao = 1; // 1: Disponível, 2: Adotado
  String _nomeDono = ''; // Nome do dono para exibição
  String? _responsiblePhone; // Telefone do responsável (dono)
  int? _animalOwnerId; // ID do usuário dono do animal
  bool _isOwner = false; // Flag para verificar se o usuário logado é o dono

  // Image lists
  List<dynamic> _animalImages = []; // Combina URLs existentes e novos Files
  final List<String> _existingImageUrls = []; // Mantém track das URLs originais
  final List<File> _newImages =
      []; // Mantém track dos novos arquivos adicionados

  // UI State flags
  bool _isEditing = false;
  bool _isLoading = true;
  String? _errorMessage;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    print('DEBUG(Detalhes): initState iniciado para animal ${widget.idAnimal}');
    _fetchAnimalData();
  }

  @override
  void dispose() {
    print('DEBUG(Detalhes): dispose iniciado para animal ${widget.idAnimal}');
    _nomeController.dispose();
    _idadeController.dispose();
    _corController.dispose();
    _descricaoController.dispose();
    _especieController.dispose();
    _racaController.dispose();
    super.dispose();
  }

  // --- Busca de Dados ---
  Future<void> _fetchAnimalData() async {
    print(
        'DEBUG(Detalhes): _fetchAnimalData iniciado para animal ${widget.idAnimal}.');
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int? currentUserId = prefs.getInt('id_usuario');

      // *** URL CORRIGIDA E INTERPOLADA ***
      final response = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/api/animais/${widget.idAnimal}'))
          .timeout(const Duration(seconds: 30));

      print(
          'DEBUG(Detalhes): Resposta recebida. Status: ${response.statusCode}');

      if (!mounted) return;

      if (response.statusCode == 200) {
        // Ajuste 'animal' se a chave principal do seu JSON for outra
        final data = json.decode(response.body)['animal'];

        print('DEBUG(Detalhes): Dados recebidos da API: $data');
        print('DEBUG(Detalhes): Campo "imagens" da API: ${data['imagens']}');

        _nomeController.text = data['nome'] ?? '';
        _idadeController.text = data['idade']?.toString() ?? '';
        _corController.text = data['cor'] ?? '';
        _descricaoController.text = data['descricao'] ?? '';
        _especieController.text = data['especie'] ?? '';
        _racaController.text = data['raca'] ?? '';
        _sexo = data['sexo'] ?? 'Macho';
        _porte = data['porte'] ?? 'Pequeno';
        _idSituacao = data['id_situacao'] ?? 1;
        _animalOwnerId = data['id_usuario'];
        _nomeDono = data['usuario']?['nome'] ?? 'Dono não informado';
        _responsiblePhone = data['usuario']?['telefone'];

        _existingImageUrls.clear();
        _newImages.clear();
        _animalImages.clear();
        if (data['imagens'] != null && data['imagens'] is List) {
          List<dynamic> imagesFromApi = data['imagens'];
          print(
              'DEBUG(Detalhes): Processando ${imagesFromApi.length} imagens da API.');
          for (var imgUrl in imagesFromApi) {
            if (imgUrl is String && imgUrl.isNotEmpty) {
              _existingImageUrls.add(imgUrl);
              _animalImages.add(imgUrl);
            } else {
              print(
                  'DEBUG(Detalhes): Item inválido encontrado no array de imagens da API: $imgUrl');
            }
          }
        }

        _isOwner = (currentUserId != null &&
            _animalOwnerId != null &&
            currentUserId == _animalOwnerId);

        setState(() {
          _isLoading = false;
        });

        print(
            'DEBUG(Detalhes): Animal carregado com sucesso. Dono: $_isOwner (User: $currentUserId, Owner: $_animalOwnerId)');
      } else {
        print(
            'DEBUG(Detalhes): Erro ${response.statusCode} ao carregar dados.');
        String errorMsg = 'Erro ao carregar detalhes do animal.';
        try {
          final errorBody = jsonDecode(response.body);
          if (errorBody['message'] != null) {
            errorMsg = errorBody['message'];
          } else if (errorBody['error'] != null) {
            errorMsg = errorBody['error'];
          }
        } catch (e) {/* Ignora erro no decode do erro */}
        throw Exception(errorMsg);
      }
    } catch (e) {
      print('DEBUG(Detalhes): Erro ao buscar animal: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e is Exception
              ? e.toString().replaceFirst('Exception: ', '')
              : 'Erro desconhecido ao carregar.';
          _isLoading = false;
        });
      }
    }
    print('DEBUG(Detalhes): _fetchAnimalData finalizado.');
  }

  // --- Funções de Imagem ---
  Future<void> _escolherOrigemImagem() async {
    if (_isLoading) return;

    final origem = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Galeria'),
                  onTap: () => Navigator.of(context).pop(ImageSource.gallery)),
              ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text('Câmera'),
                  onTap: () => Navigator.of(context).pop(ImageSource.camera)),
            ],
          ),
        );
      },
    );

    if (origem == ImageSource.gallery) {
      _pickMultipleImages();
    } else if (origem == ImageSource.camera) {
      _pickSingleImageFromCamera();
    }
  }

  Future<void> _pickMultipleImages() async {
    try {
      final List<XFile> pickedFiles =
          await _picker.pickMultiImage(imageQuality: 80);
      if (pickedFiles.isNotEmpty && mounted) {
        for (var xfile in pickedFiles) {
          File? croppedFile = await _cropImage(File(xfile.path));
          if (croppedFile != null && mounted) {
            setState(() {
              _newImages.add(croppedFile);
              _animalImages.add(croppedFile);
            });
          }
        }
      }
    } catch (e) {
      print("Erro ao selecionar imagens da galeria: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao selecionar imagens.')));
      }
    }
  }

  Future<void> _pickSingleImageFromCamera() async {
    try {
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
      if (pickedFile != null && mounted) {
        File? croppedFile = await _cropImage(File(pickedFile.path));
        if (croppedFile != null && mounted) {
          setState(() {
            _newImages.add(croppedFile);
            _animalImages.add(croppedFile);
          });
        }
      }
    } catch (e) {
      print("Erro ao capturar imagem da câmera: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao usar a câmera.')));
      }
    }
  }

  Future<File?> _cropImage(File imageFile) async {
    // *** CORREÇÃO APLICADA: Removido aspectRatioPresets direto ***
    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      // aspectRatioPresets: [], // <--- REMOVIDO
      uiSettings: [
        AndroidUiSettings(
            toolbarTitle: 'Recortar Imagem',
            toolbarColor: Colors.deepOrange,
            toolbarWidgetColor: Colors.white,
            initAspectRatio:
                CropAspectRatioPreset.ratio4x3, // Pode manter ou remover isso
            lockAspectRatio: false),
        IOSUiSettings(
            title: 'Recortar Imagem',
            aspectRatioLockEnabled: false // Mantém flexibilidade
            ),
        // WebUiSettings não precisa estar aqui se não for app web
        // WebUiSettings(context: context),
      ],
      // compressFormat: ImageCompressFormat.jpg, // Opcional: Forçar formato
      // compressQuality: 75, // Opcional: Definir qualidade da compressão
    );
    return croppedFile != null ? File(croppedFile.path) : null;
  }

  void _removerImagem(int index) {
    if (_isLoading || !_isEditing) return;

    setState(() {
      dynamic imageToRemove = _animalImages[index];
      _animalImages.removeAt(index);

      if (imageToRemove is String) {
        _existingImageUrls.remove(imageToRemove);
        print(
            "DEBUG(Detalhes): Imagem existente removida da UI: $imageToRemove");
      } else if (imageToRemove is File) {
        _newImages.remove(imageToRemove);
        print(
            "DEBUG(Detalhes): Nova imagem removida da UI: ${imageToRemove.path}");
      }
    });
  }

  // --- Ações (Editar, Salvar, Excluir, Adotar, Favoritar) ---

  void _toggleEdit() {
    print('DEBUG(Detalhes): _toggleEdit - isEditing: $_isEditing');
    if (_isEditing) {
      _salvarEdicao();
    } // Tenta salvar
    else {
      // Entrar no modo de edição
      if (_isOwner) {
        if (!mounted) return;
        setState(() {
          print(
              'DEBUG(Detalhes): setState (_toggleEdit - entrando em modo de edição)');
          _isEditing = true;
        });
      } else {
        print('DEBUG(Detalhes): Tentativa de editar sem ser o dono.');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Você não pode editar este anúncio.')));
        }
      }
    }
  }

  Future<void> _salvarEdicao() async {
    if (!_isEditing || _isLoading) return;
    print('DEBUG(Detalhes): _salvarEdicao iniciado.');

    if (!_formKey.currentState!.validate()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Preencha todos os campos obrigatórios.')));
      }
      print('DEBUG(Detalhes): _salvarEdicao - Validação do formulário falhou.');
      return;
    }
    if (_animalImages.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Adicione pelo menos uma imagem.')));
      }
      print('DEBUG(Detalhes): _salvarEdicao - Nenhuma imagem selecionada.');
      return;
    }

    if (!mounted) return;
    setState(() {
      print('DEBUG(Detalhes): setState (_salvarEdicao - isLoading=true)');
      _isLoading = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int? idUsuario = prefs.getInt('id_usuario');
      if (idUsuario == null || idUsuario != _animalOwnerId) {
        throw Exception(
            'Usuário não autenticado ou não autorizado para salvar.');
      }

      var uri = Uri.parse(
          '${ApiConfig.baseUrl}/api/animais/atualizar/${widget.idAnimal}');
      var request = http.MultipartRequest('POST', uri);
      request.fields['_method'] = 'PUT';
      request.fields['id_animal'] = widget.idAnimal.toString();
      request.fields['id_usuario'] = idUsuario.toString();
      request.fields['nome'] = _nomeController.text.trim();
      request.fields['idade'] = _idadeController.text.trim();
      request.fields['cor'] = _corController.text.trim();
      request.fields['sexo'] = _sexo;
      request.fields['porte'] = _porte;
      request.fields['descricao'] = _descricaoController.text.trim();
      request.fields['especie'] = _especieController.text.trim();
      request.fields['raca'] = _racaController.text.trim();
      request.fields['id_situacao'] = _idSituacao.toString();

      for (var imgFile in _newImages) {
        request.files.add(
            await http.MultipartFile.fromPath('novas_imagens[]', imgFile.path));
      }

      debugPrint(
          'DEBUG(Detalhes): Enviando dados para atualização... Campos: ${request.fields.length}, Imagens Existentes: ${_existingImageUrls.length}, Novas Imagens: ${_newImages.length}');
      var response = await request.send().timeout(const Duration(seconds: 45));
      final responseBody = await response.stream.bytesToString();

      if (!mounted) {
        print(
            'DEBUG(Detalhes): Widget desmontado após requisição de atualização.');
        return;
      }
      debugPrint(
          'DEBUG(Detalhes): Resposta da atualização: Status ${response.statusCode}, Body: $responseBody');

      if (response.statusCode == 200) {
        print('DEBUG(Detalhes): _salvarEdicao - Sucesso.');
        if (mounted) {
          // Checa mounted antes do SnackBar e Pop
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Anúncio atualizado com sucesso!')));
          Navigator.pop(context, true); // <--- RETORNA true
        }
      } else {
        print(
            'DEBUG(Detalhes): _salvarEdicao - Erro no backend. Status: ${response.statusCode}');
        String errorMessage = 'Erro ao atualizar anúncio.';
        try {
          final errorData = jsonDecode(responseBody);
          if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          } else if (errorData['error'] != null) {
            errorMessage = errorData['error'];
          } else {
            errorMessage = 'Erro ${response.statusCode}.';
          }
        } catch (e) {
          debugPrint(
              'DEBUG(Detalhes): Erro ao decodificar resposta de erro: $e');
          errorMessage = 'Erro ${response.statusCode} ao atualizar.';
        }
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(errorMessage)));
          setState(() {
            _isLoading = false;
            _isEditing = true;
          });
        }
        print('DEBUG(Detalhes): _salvarEdicao - Erro backend finalizado.');
      }
    } catch (e) {
      debugPrint(
          'DEBUG(Detalhes): Erro na comunicação ou processamento ao salvar edição: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isEditing = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Erro ao salvar: ${e.toString().replaceFirst("Exception: ", "")}')),
      );
      print('DEBUG(Detalhes): _salvarEdicao - Erro catch finalizado.');
    } finally {
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    }
    print('DEBUG(Detalhes): _salvarEdicao finalizado (fim do método).');
  }
Future<void> _excluirAnimal() async {
  if (!_isOwner || _isLoading) return;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Confirmar Exclusão'),
      content: const Text('Tem certeza que deseja excluir permanentemente este anúncio?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Excluir', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  ) ?? false;

  if (!confirmed || !mounted) return;

  setState(() => _isLoading = true);

  try {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('id_usuario');
    
    if (userId == null) {
      throw Exception('Usuário não autenticado');
    }

    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/api/animais/${widget.idAnimal}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id_usuario': userId}),
    );

    if (!mounted) return;

    if (response.statusCode == 204) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Anúncio excluído com sucesso!')),
        );
        Navigator.pop(context, true);
      }
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Falha ao excluir anúncio');
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}


  Future<void> _marcarAdotado() async {
    if (!_isOwner || _isLoading || _idSituacao == 2) {
      if (!_isOwner && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Você não pode alterar o status.')));
      } else if (_idSituacao == 2 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Animal já está marcado como adotado.')));
      }
      return;
    }
    print('DEBUG(Detalhes): _marcarAdotado iniciado.');
    if (!mounted) return;

    bool confirmar = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirmar Adoção'),
            content: const Text('Marcar este animal como adotado?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar')),
              TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Confirmar'),
                  style: TextButton.styleFrom(foregroundColor: Colors.green)),
            ],
          ),
        ) ??
        false;

    if (confirmar) {
      if (!mounted) return;
      setState(() {
        print('DEBUG(Detalhes): setState (_marcarAdotado - isLoading=true)');
        _isLoading = true;
      });

      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        int? idUsuario = prefs.getInt('id_usuario');
        if (idUsuario == null || idUsuario != _animalOwnerId) {
          throw Exception(
              'Usuário não autenticado ou não autorizado para marcar como adotado.');
        }

        var uri = Uri.parse(
            '${ApiConfig.baseUrl}/api/animais/atualizar/${widget.idAnimal}');
        var request = http.MultipartRequest('POST', uri);
        request.fields['_method'] = 'PUT';
        request.fields['id_animal'] = widget.idAnimal.toString();
        request.fields['id_usuario'] = idUsuario.toString();
        request.fields['id_situacao'] = '2'; // <<< Alteração principal aqui
        request.fields['nome'] = _nomeController.text.trim();
        request.fields['idade'] = _idadeController.text.trim();
        request.fields['cor'] = _corController.text.trim();
        request.fields['sexo'] = _sexo;
        request.fields['porte'] = _porte;
        request.fields['descricao'] = _descricaoController.text.trim();
        request.fields['especie'] = _especieController.text.trim();
        request.fields['raca'] = _racaController.text.trim();

        var response =
            await request.send().timeout(const Duration(seconds: 30));
        final responseBody = await response.stream.bytesToString();

        if (!mounted) {
          print(
              'DEBUG(Detalhes): Widget desmontado após requisição de marcar adotado.');
          return;
        }
        debugPrint(
            'DEBUG(Detalhes): Resposta de marcar como adotado: Status ${response.statusCode}, Body: $responseBody');

        if (response.statusCode == 200) {
          print('DEBUG(Detalhes): _marcarAdotado - Sucesso.');
          if (mounted) {
            // Checa mounted antes do setState, SnackBar e Pop
            setState(() {
              _idSituacao = 2;
            }); // Atualiza estado local ANTES de sair
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Animal marcado como adotado!')));
            Navigator.pop(context, true); // <--- RETORNA true
          }
        } else {
          print(
              'DEBUG(Detalhes): _marcarAdotado - Erro no backend. Status: ${response.statusCode}');
          String errorMessage = 'Erro ao marcar como adotado.';
          try {
            final errorData = jsonDecode(responseBody);
            if (errorData['message'] != null) {
              errorMessage = errorData['message'];
            } else if (errorData['error'] != null) {
              errorMessage = errorData['error'];
            } else {
              errorMessage = 'Erro ${response.statusCode}.';
            }
          } catch (e) {
            debugPrint(
                'DEBUG(Detalhes): Erro ao decodificar resposta de erro ao marcar adotado: $e');
            errorMessage =
                'Erro ${response.statusCode} ao marcar como adotado.';
          }
          if (mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(errorMessage)));
            setState(() {
              _isLoading = false;
            });
          }
          print('DEBUG(Detalhes): _marcarAdotado - Erro backend finalizado.');
        }
      } catch (e) {
        debugPrint(
            'DEBUG(Detalhes): Erro na comunicação ou processamento ao marcar adotado: $e');
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Erro ao marcar como adotado: ${e.toString().replaceFirst("Exception: ", "")}')),
        );
        print('DEBUG(Detalhes): _marcarAdotado - Erro catch finalizado.');
      } finally {
        if (mounted && _isLoading) {
          setState(() {
            _isLoading = false;
          });
        }
      }
      print('DEBUG(Detalhes): _marcarAdotado finalizado (fim do método).');
    } else {
      print('DEBUG(Detalhes): Ação de marcar como adotado cancelada.');
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isLoading) return;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? idUsuario = prefs.getInt('id_usuario');
    if (idUsuario == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login necessário para favoritar.')));
      }
      return;
    }
    final int idAnimal = widget.idAnimal;
    // Substitua pela URL correta da sua API de favoritos
    var uri = Uri.parse(
        '${ApiConfig.baseUrl}/api/usuarios/$idUsuario/favoritos/$idAnimal'); // Exemplo
    try {
      var response = await http.post(uri, headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      }).timeout(const Duration(seconds: 10));
      if (!mounted) return;
      final responseData = jsonDecode(response.body);
      final bool backendIsFavorited = responseData['isFavorited'] ?? false;
      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(responseData['message'] ??
                (backendIsFavorited
                    ? 'Adicionado aos favoritos!'
                    : 'Removido dos favoritos!'))));
      } else {
        String errorMessage = responseData['message'] ??
            responseData['error'] ??
            'Erro ${response.statusCode} ao favoritar.';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro de comunicação ao favoritar.')));
      }
    }
  }

  // --- Widgets de Construção da UI ---
  Widget _buildTextField(TextEditingController controller, String label,
      {bool isEditable = true,
      TextInputType tipo = TextInputType.text,
      int maxLines = 1,
      String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      enabled: isEditable && _isEditing,
      keyboardType: tipo,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        filled: !isEditable || !_isEditing,
        fillColor: Colors.grey[100],
        border: const OutlineInputBorder(),
        disabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey[300]!)),
      ),
      validator: validator ??
          (value) {
            if (_isEditing) {
              if (value == null || value.trim().isEmpty) {
                return 'Campo obrigatório';
              }
              if (tipo == TextInputType.number) {
                final intValue = int.tryParse(value.trim());
                if (intValue == null || intValue < 0) {
                  return 'Número inválido';
                }
              }
            }
            return null;
          },
    );
  }

  Widget _buildSexoSelector({bool isEditable = true}) {
    bool enabled = isEditable && _isEditing;
    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Sexo',
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        filled: !enabled,
        fillColor: Colors.grey[100],
        disabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Expanded(
              child: ListTile(
                  title: Text('Macho',
                      style: TextStyle(
                          color: enabled ? Colors.black : Colors.grey[600])),
                  leading: Radio<String>(
                      value: 'Macho',
                      groupValue: _sexo,
                      onChanged:
                          enabled ? (v) => setState(() => _sexo = v!) : null),
                  contentPadding: EdgeInsets.zero,
                  dense: true)),
          Expanded(
              child: ListTile(
                  title: Text('Fêmea',
                      style: TextStyle(
                          color: enabled ? Colors.black : Colors.grey[600])),
                  leading: Radio<String>(
                      value: 'Fêmea',
                      groupValue: _sexo,
                      onChanged:
                          enabled ? (v) => setState(() => _sexo = v!) : null),
                  contentPadding: EdgeInsets.zero,
                  dense: true)),
        ],
      ),
    );
  }

  Widget _buildPorteSelector({bool isEditable = true}) {
    bool enabled = isEditable && _isEditing;
    return DropdownButtonFormField<String>(
      value: _porte,
      onChanged: enabled ? (v) => setState(() => _porte = v!) : null,
      decoration: InputDecoration(
        labelText: 'Porte',
        border: const OutlineInputBorder(),
        filled: !enabled,
        fillColor: Colors.grey[100],
        disabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey[300]!)),
      ),
      items: <String>['Pequeno', 'Médio', 'Grande']
          .map<DropdownMenuItem<String>>(
              (v) => DropdownMenuItem<String>(value: v, child: Text(v)))
          .toList(),
      validator: (v) =>
          (_isEditing && (v == null || v.isEmpty)) ? 'Selecione o porte' : null,
      selectedItemBuilder: (ctx) => <String>['Pequeno', 'Médio', 'Grande']
          .map<Widget>((i) => Text(i,
              style:
                  TextStyle(color: enabled ? Colors.black : Colors.grey[600])))
          .toList(),
      iconDisabledColor: Colors.grey[400],
      iconEnabledColor: Colors.grey[700],
    );
  }

  // --- Funções de Lançamento (Telefone, WhatsApp) ---
  Future<void> _launchPhoneCall(String phoneNumber) async {
    if (_isLoading) return;
    final Uri launchUri =
        Uri(scheme: 'tel', path: phoneNumber.replaceAll(RegExp(r'[^\d+]'), ''));
    try {
      if (!await launchUrl(launchUri) && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Não foi possível realizar a chamada.')));
      }
    } catch (e) {
      debugPrint('Erro ao tentar ligar para $phoneNumber: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao tentar realizar chamada.')));
      }
    }
  }

  Future<void> _launchWhatsApp(String phoneNumber) async {
    if (_isLoading) return;
    final String cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri launchUri = Uri.parse('https://wa.me/$cleanedNumber');
    try {
      bool launched =
          await launchUrl(launchUri, mode: LaunchMode.externalApplication);
      if (!launched) {
        final Uri webLaunchUri =
            Uri.parse('https://web.whatsapp.com/send?phone=$cleanedNumber');
        launched =
            await launchUrl(webLaunchUri, mode: LaunchMode.platformDefault);
        if (!launched && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Não foi possível abrir o WhatsApp.')));
        }
      }
    } catch (e) {
      debugPrint('Erro ao tentar abrir WhatsApp para $phoneNumber: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao tentar abrir WhatsApp.')));
      }
    }
  }

  // --- Método Build Principal ---
  @override
  Widget build(BuildContext context) {
    print(
        'DEBUG(Detalhes): build iniciado. isLoading: $_isLoading, isEditing: $_isEditing, isOwner: $_isOwner');

    if (_isLoading && _animalImages.isEmpty && _errorMessage == null) {
      return Scaffold(
          appBar: AppBar(title: const Text('Carregando Detalhes...')),
          body: const Center(child: CircularProgressIndicator()));
    }
    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Erro')),
        body: Center(
            child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage!,
                          textAlign: TextAlign.center,
                          style:
                              const TextStyle(color: Colors.red, fontSize: 16)),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('Tentar Novamente'),
                          onPressed: _fetchAnimalData)
                    ]))),
      );
    }

    bool isAdotado = _idSituacao == 2;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing
            ? 'Editar Anúncio'
            : (isAdotado ? 'Animal Adotado' : 'Detalhes do Animal')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isLoading
              ? null
              : () async {
                  if (_isEditing) {
                    bool descartar = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Descartar Alterações?"),
                            content: const Text("Sair sem salvar?"),
                            actions: [
                              TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text("Cancelar")),
                              TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text("Descartar"))
                            ],
                          ),
                        ) ??
                        false;
                    if (descartar && mounted) {
                      Navigator.pop(context, false);
                    } // Retorna FALSE ao descartar
                  } else {
                    Navigator.pop(context, false);
                  } // Retorna FALSE ao voltar normalmente
                },
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.favorite_border),
              color: Colors.red,
              onPressed: _isLoading ? null : _toggleFavorite,
              tooltip: 'Favoritar/Desfavoritar'),
          if (_isOwner && !isAdotado)
            IconButton(
                icon: Icon(_isEditing ? Icons.save : Icons.edit),
                onPressed: _isLoading ? null : _toggleEdit,
                tooltip: _isEditing ? 'Salvar Alterações' : 'Editar Anúncio'),
          if (_isOwner && !_isEditing)
            IconButton(
                icon: const Icon(Icons.delete_outline),
                color: Colors.red[700],
                onPressed: _isLoading ? null : _excluirAnimal,
                tooltip: 'Excluir Anúncio'),
        ],
      ),
      body: IgnorePointer(
        ignoring: _isLoading,
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Seção de Imagens ---
                    if (_isEditing)
                      Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Center(
                              child: ElevatedButton.icon(
                                  icon: const Icon(Icons.add_a_photo),
                                  label: Text(_animalImages.isEmpty
                                      ? 'Adicionar Imagens'
                                      : 'Adicionar Mais Imagens'),
                                  onPressed: _escolherOrigemImagem))),
                    if (_animalImages.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child: CarouselSlider(
                          options: CarouselOptions(
                              height: 250,
                              viewportFraction:
                                  _animalImages.length > 1 ? 0.85 : 1.0,
                              initialPage: 0,
                              enableInfiniteScroll: _animalImages.length > 1,
                              enlargeCenterPage: _animalImages.length > 1,
                              autoPlay: false),
                          items: _animalImages.asMap().entries.map((entry) {
                            int index = entry.key;
                            dynamic imageSource = entry.value;
                            return Builder(builder: (BuildContext context) {
                              return GestureDetector(
                                  onTap: () {
                                    if (imageSource != null) {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  ImageViewerScreen(
                                                    // *** CORREÇÃO APLICADA: Removido isFilePath ***
                                                    // Você PRECISA garantir que ImageViewerScreen consiga lidar com URL (String) e Path (File)
                                                    imageSource: imageSource
                                                            is String
                                                        ? imageSource
                                                        : (imageSource as File)
                                                            .path,
                                                    // isFilePath: imageSource is File, // <--- REMOVIDO
                                                  )));
                                    }
                                  },
                                  child: Container(
                                      width: MediaQuery.of(context).size.width,
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 5.0),
                                      child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                          child: Stack(
                                              fit: StackFit.expand,
                                              children: [
                                                imageSource is String
                                                    ? Image.network(imageSource,
                                                        fit: BoxFit.cover,
                                                        loadingBuilder: (ctx, child, prog) => (prog ==
                                                                null)
                                                            ? child
                                                            : Center(
                                                                child: CircularProgressIndicator(
                                                                    value: prog.expectedTotalBytes !=
                                                                            null
                                                                        ? prog.cumulativeBytesLoaded /
                                                                            prog
                                                                                .expectedTotalBytes!
                                                                        : null)),
                                                        errorBuilder:
                                                            (ctx, err, st) {
                                                          print(
                                                              "Erro NetworkImage: $imageSource, $err");
                                                          return Container(
                                                              color: Colors
                                                                  .grey[200],
                                                              child: Icon(
                                                                  Icons
                                                                      .broken_image,
                                                                  size: 50,
                                                                  color: Colors
                                                                          .grey[
                                                                      400]));
                                                        })
                                                    : Image.file(
                                                        imageSource as File,
                                                        fit: BoxFit.cover,
                                                        errorBuilder:
                                                            (ctx, err, st) {
                                                        print(
                                                            "Erro FileImage: ${imageSource.path}, $err");
                                                        return Container(
                                                            color: Colors
                                                                .grey[200],
                                                            child: Icon(
                                                                Icons
                                                                    .broken_image,
                                                                size: 50,
                                                                color:
                                                                    Colors.grey[
                                                                        400]));
                                                      }),
                                                if (_isEditing)
                                                  Positioned(
                                                      right: 5,
                                                      top: 5,
                                                      child: GestureDetector(
                                                          onTap: () =>
                                                              _removerImagem(
                                                                  index),
                                                          child: Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(4),
                                                              decoration: BoxDecoration(
                                                                  color: Colors
                                                                      .black
                                                                      .withOpacity(
                                                                          0.6),
                                                                  shape: BoxShape
                                                                      .circle),
                                                              child: const Icon(
                                                                  Icons.close,
                                                                  color:
                                                                      Colors.white,
                                                                  size: 18)))),
                                              ]))));
                            });
                          }).toList(),
                        ),
                      ),
                    if (_animalImages.isEmpty && !_isEditing)
                      const Center(
                          child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 40.0),
                              child: Text("Nenhuma imagem disponível.",
                                  style: TextStyle(color: Colors.grey)))),

                    // --- Campos do Formulário ---
                    _buildTextField(_nomeController, 'Nome do Animal',
                        isEditable: true),
                    const SizedBox(height: 16),
                    _buildTextField(_idadeController, 'Idade (anos)',
                        isEditable: true,
                        tipo: TextInputType.number,
                        validator: (v) => (_isEditing &&
                                (v == null ||
                                    v.trim().isEmpty ||
                                    int.tryParse(v.trim()) == null ||
                                    int.tryParse(v.trim())! < 0))
                            ? 'Idade inválida'
                            : null),
                    const SizedBox(height: 16),
                    _buildTextField(_corController, 'Cor', isEditable: true),
                    const SizedBox(height: 16),
                    _buildSexoSelector(isEditable: true),
                    const SizedBox(height: 16),
                    _buildPorteSelector(isEditable: true),
                    const SizedBox(height: 16),
                    _buildTextField(_especieController, 'Espécie',
                        isEditable: true),
                    const SizedBox(height: 16),
                    _buildTextField(_racaController, 'Raça', isEditable: true),
                    const SizedBox(height: 16),
                    _buildTextField(
                        _descricaoController, 'Descrição / Observações',
                        isEditable: true, maxLines: 4),
                    const SizedBox(height: 20),

                    // --- Informações do Dono e Contato ---
                    if (!_isEditing)
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(height: 30, thickness: 1),
                            Text('Publicado por: $_nomeDono',
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w500)),
                            if (_responsiblePhone != null &&
                                _responsiblePhone!.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              const Text('Entrar em contato:',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    ElevatedButton.icon(
                                        icon: const Icon(Icons.phone),
                                        label: const Text("Ligar"),
                                        onPressed: () => _launchPhoneCall(
                                            _responsiblePhone!),
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color.fromARGB(255, 228, 234, 228))),
                                    ElevatedButton.icon(
                                        icon: Image.asset(
                                            'assets/images/whatsapp_icon.png',
                                            height: 20,
                                            width: 20),
                                        label: const Text("WhatsApp"),
                                        onPressed: () =>
                                            _launchWhatsApp(_responsiblePhone!),
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color.fromARGB(255, 228, 234, 228))),
                                  ]),
                            ],
                            const Divider(height: 30, thickness: 1),
                          ]),

                    // --- Botão Marcar como Adotado ---
                    if (_isOwner && !isAdotado && !_isEditing)
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20.0),
                          child: Center(
                              child: ElevatedButton.icon(
                                  onPressed: _marcarAdotado,
                                  icon: const Icon(Icons.check_circle_outline),
                                  label: const Text('Marcar como Adotado'),
                                  style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 24, vertical: 12),
                                      textStyle: const TextStyle(fontSize: 16),
                                      backgroundColor: Colors.orange[700],
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)))))),

                    // --- Indicador de Adotado ---
                    if (isAdotado && !_isEditing)
                      Center(
                          child: Chip(
                              avatar: Icon(Icons.pets, color: Colors.white),
                              label: Text('ADOTADO',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                              backgroundColor: Colors.green[600],
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8))),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            // --- Overlay de Loading ---
            if (_isLoading)
              Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(child: CircularProgressIndicator())),
          ],
        ),
      ),
    );
  }
}
