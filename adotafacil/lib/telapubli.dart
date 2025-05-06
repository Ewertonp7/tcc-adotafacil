import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:http/http.dart' as http;
import 'package:adotafacil/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'telaanimalpublicado.dart'; // Certifique-se que o nome do arquivo está correto
import 'dart:convert';
import 'image_viewer_screen.dart'; // Certifique-se que o nome do arquivo está correto


class TelaPubli extends StatefulWidget {
  const TelaPubli({Key? key}) : super(key: key);

  @override
  _TelaPubliState createState() => _TelaPubliState();
}

class _TelaPubliState extends State<TelaPubli> {
  final _formKey = GlobalKey<FormState>();

  final _nomeController = TextEditingController();
  final _idadeController = TextEditingController();
  final _corController = TextEditingController(); // <--- ADICIONADO Controller para Cor

  String _sexo = 'Macho';
  String _porte = 'Pequeno';
  final _descricaoController = TextEditingController();
  final _especieController = TextEditingController();
  final _racaController = TextEditingController();
  List<File> _imagens = [];

  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _nomeController.dispose();
    _idadeController.dispose();
    _corController.dispose(); // <--- ADICIONADO Dispose para Cor
    _descricaoController.dispose();
    _especieController.dispose();
    _racaController.dispose();
    super.dispose();
  }


  Future<void> _escolherOrigemImagem() async {
     // check mounted antes de async gap
    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      builder: (context) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Selecionar da Galeria'),
            onTap: () {
              Navigator.pop(context);
              _pickMultipleImages();
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Tirar Foto'),
            onTap: () {
              Navigator.pop(context);
              _pickSingleImageFromCamera();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _pickMultipleImages() async {
    try {
      final pickedFiles = await _picker.pickMultiImage();

      if (pickedFiles != null) {
         // check mounted antes de setState
         if (!mounted) return;
        if ((_imagens.length + pickedFiles.length) > 5) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Máximo de 5 imagens permitidas.')),
          );
          return;
        }

        for (var pickedFile in pickedFiles) {
          File? cropped = await _cropImage(File(pickedFile.path));
          if (cropped != null) {
             // check mounted antes de setState
             if (!mounted) return;
            setState(() {
              _imagens.add(cropped);
            });
          } else {
             // Se o corte for cancelado ou falhar, use a imagem original
             if (!mounted) return; // check mounted antes de setState
             setState(() {
                _imagens.add(File(pickedFile.path));
             });
          }
        }
      }
    } catch (e) {
      debugPrint('Erro ao selecionar múltiplas imagens: $e');
    }
  }

  Future<void> _pickSingleImageFromCamera() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.camera);

      if (pickedFile != null) {
         // check mounted antes de async gap
        if (!mounted) return;
        File? cropped = await _cropImage(File(pickedFile.path));
        if (cropped != null) {
          if (_imagens.length >= 5) {
             // check mounted antes de ScaffoldMessenger
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Máximo de 5 imagens permitidas.')),
            );
            return;
          }
           // check mounted antes de setState
          if (!mounted) return;
          setState(() {
            _imagens.add(cropped);
          });
        } else {
           // Se o corte for cancelado ou falhar, use a imagem original
          if (_imagens.length >= 5) {
             // check mounted antes de ScaffoldMessenger
             if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Máximo de 5 imagens permitidas.')),
            );
            return;
          }
           // check mounted antes de setState
           if (!mounted) return;
           setState(() {
             _imagens.add(File(pickedFile.path));
           });
        }
      }
    } catch (e) {
      debugPrint('Erro ao tirar foto: $e');
    }
  }

  Future<File?> _cropImage(File imageFile) async {
    try {
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Editar Imagem',
            toolbarColor: Colors.deepPurple,
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: Colors.deepPurple,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Editar Imagem',
          ),
        ],
      );
      if (croppedFile != null) {
        return File(croppedFile.path);
      }
    } catch (e) {
      debugPrint('Erro ao cortar imagem: $e');
    }
    return null; // Retorna null se o corte for cancelado ou falhar
  }


   void _removerImagem(int index) {
      setState(() {
        _imagens.removeAt(index);
      });
   }


  Future<void> _publicarAnimal() async {
     // check mounted antes de async gap
    if (!mounted) return;

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos corretamente.')),
      );
      return;
    }

    if (_imagens.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione ao menos uma imagem.')),
      );
      return;
    }

    try {
       // check mounted antes de setState
      if (!mounted) return;
      setState(() {
        _isLoading = true;
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      int? idUsuario = prefs.getInt('id_usuario');

      if (idUsuario == null) {
         // check mounted antes de ScaffoldMessenger e setState
         if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuário não encontrado. Faça login novamente.')),
        );
         if (!mounted) return; setState(() { _isLoading = false; }); // check mounted again
        return;
      }

      var uri = Uri.parse('${ApiConfig.baseUrl}/api/animais/cadastrar');
      var request = http.MultipartRequest('POST', uri);

      request.fields['id_usuario'] = idUsuario.toString();
      request.fields['nome'] = _nomeController.text.trim();
      request.fields['idade'] = _idadeController.text.trim();
      request.fields['cor'] = _corController.text.trim(); // <--- Envia dados da Cor

      request.fields['sexo'] = _sexo;
      request.fields['descricao'] = _descricaoController.text.trim();
      request.fields['especie'] = _especieController.text.trim();
      request.fields['raca'] = _racaController.text.trim();
      request.fields['porte'] = _porte;
      request.fields['id_situacao'] = '1'; // 1 é o ID para "Disponível" (ajuste conforme seu BD)


      for (var img in _imagens) {
        request.files.add(await http.MultipartFile.fromPath('imagens[]', img.path));
      }

      debugPrint('Enviando dados...');
      debugPrint('-> Prestes a aguardar response...');
      var response = await request.send();
      debugPrint('-> Response recebida, aguardando corpo...');
      final responseBody = await response.stream.bytesToString();
      debugPrint('-> Corpo recebido.');
      debugPrint('Status: ${response.statusCode}');
      debugPrint('Corpo: $responseBody');

       // check mounted antes de setState
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final Map<String, dynamic> responseData = jsonDecode(responseBody);
           // Verifica se 'id_animal' existe e é um número
          final int? idAnimal = responseData['id_animal'] is int ? responseData['id_animal'] : null;

          if (idAnimal == null) {
              debugPrint('Erro: Resposta do backend não contém id_animal válido.');
               if (!mounted) return;
               ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(content: Text('Sucesso na publicação, mas erro ao obter ID do animal: ${responseBody}')),
               );
               // Opcional: Limpar formulário mesmo com erro no ID
               _clearForm();
          } else {
               if (!mounted) return;
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('Animal publicado com sucesso!')),
             );

             // Limpa o formulário após sucesso na publicação
             _clearForm();

             // Opcional: Navegar para a tela do animal publicado
             Navigator.pushReplacement( // Usar pushReplacement para não poder voltar para a tela de publicação
               context,
               MaterialPageRoute(
                 builder: (context) => TelaAnimalPublicado(
                   idAnimal: idAnimal,
                 ),
               ),
             );
          }


        } catch (e) {
          debugPrint('Erro ao processar resposta JSON do backend após publicação: $e');
           if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Sucesso na publicação, mas erro ao processar dados de retorno: $e')),
          );
           // Opcional: Limpar formulário mesmo com erro no processamento da resposta
          _clearForm();
        }
      } else {
        String errorMessage = 'Erro ao publicar: Status ${response.statusCode}';
        if (responseBody.isNotEmpty) {
            try {
              final errorData = jsonDecode(responseBody);
               if (errorData != null) {
                    if (errorData['error'] != null) {
                    errorMessage = 'Erro ao publicar: ${errorData['error']}';
                    } else if (errorData['message'] != null) {
                    errorMessage = 'Erro ao publicar: ${errorData['message']}';
                    } else {
                     errorMessage = 'Erro ao publicar: Status ${response.statusCode} - $responseBody';
                    }
               }
            } catch (e) {
              errorMessage = 'Erro ao publicar: Status ${response.statusCode} - $responseBody';
            }
        }
         if (!mounted) return; // check mounted antes de ScaffoldMessenger
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      debugPrint('Erro na comunicação HTTP ao publicar animal: $e');
       // check mounted antes de setState
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
       if (!mounted) return; // check mounted antes de ScaffoldMessenger
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro de comunicação ao publicar: $e')),
      );
    }
  }

   // Função auxiliar para limpar o formulário
   void _clearForm() {
      _nomeController.clear();
      _idadeController.clear();
      _corController.clear();
      _descricaoController.clear();
      _especieController.clear();
      _racaController.clear();
      setState(() {
         _sexo = 'Macho';
         _porte = 'Pequeno';
         _imagens = []; // Limpa a lista de imagens
      });
   }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Publicar Animal'),
      ),
      body: Stack( // Usado Stack para sobrepor o indicador de loading
        children: [
          _buildFormContent(),
          // Mostra o CircularProgressIndicator se _isLoading for true
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5), // Fundo semi-transparente
              child: const Center(
                child: CircularProgressIndicator(color: Colors.deepPurple),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFormContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Imagens',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _isLoading ? null : _escolherOrigemImagem, // Desabilita se carregando
              child: Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  color: _isLoading ? Colors.grey[400] : Colors.grey[300], // Cor cinza se desabilitado
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(Icons.add_a_photo, size: 40, color: _isLoading ? Colors.grey[500] : Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 10),
             // Exibe as miniaturas das imagens selecionadas
            if (_imagens.isNotEmpty)
              GridView.builder(
                shrinkWrap: true, // Ocupa apenas o espaço necessário
                physics: const NeverScrollableScrollPhysics(), // Desabilita o scroll interno do GridView
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, // 3 imagens por linha
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _imagens.length,
                itemBuilder: (context, index) {
                  final imageFile = _imagens[index];

                  return Stack(
                    fit: StackFit.expand, // Faz a Stack ocupar todo o espaço do item do GridView
                    children: [
                       // GestureDetector para visualizar a imagem ao clicar
                      GestureDetector(
                          onTap: _isLoading ? null : () { // Desabilita clique se carregando
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ImageViewerScreen(imageSource: imageFile.path),
                              ),
                            );
                          },
                         child: ClipRRect( // Borda arredondada para a imagem
                           borderRadius: BorderRadius.circular(10),
                           child: Image.file(
                             imageFile,
                             fit: BoxFit.cover, // Cobre a área disponível
                           ),
                         ),
                      ),
                      // Botão para remover a imagem (aparece no canto superior direito)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector( // Usado GestureDetector para área de clique maior
                          onTap: _isLoading ? null : () => _removerImagem(index), // Desabilita remoção se carregando
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5), // Fundo escuro semi-transparente
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, color: Colors.white), // Ícone branco
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            const SizedBox(height: 20),
             _buildTextField(_nomeController, 'Nome do Animal'),
            const SizedBox(height: 10),
            _buildTextField(_idadeController, 'Idade (anos)', tipo: TextInputType.number,
                validator: (value) { // Validação para idade
                   if (value == null || value.isEmpty) {
                      return 'Informe a idade';
                   }
                   final intValue = int.tryParse(value);
                   if (intValue == null || intValue < 0) {
                     return 'Deve ser um número inteiro positivo';
                   }
                    return null;
                 }
            ),
            const SizedBox(height: 10),

            _buildTextField(_corController, 'Cor'), // <--- ADICIONADO Campo para Cor
            const SizedBox(height: 10),

            _buildSexoSelector(),
            const SizedBox(height: 10),

            _buildTextField(_especieController, 'Espécie'),
            const SizedBox(height: 10),

            _buildTextField(_racaController, 'Raça',
                validator: (value) { // Validação para raça (ajuste se for opcional)
                   if (value == null || value.isEmpty) {
                       return 'Por favor, informe a raça';
                   }
                   return null;
                 }
            ),
            const SizedBox(height: 10),

            _buildPorteSelector(),
            const SizedBox(height: 10),

            _buildTextField(_descricaoController, 'Descrição', maxLines: 3),
            const SizedBox(height: 20),

            Center( // Centraliza o botão de publicar
              child: ElevatedButton(
                onPressed: _isLoading ? null : _publicarAnimal, // Desabilita o botão enquanto carrega
                child: _isLoading ? const Text('Publicando...') : const Text('Publicar Animal'), // Texto dinâmico no botão
                 style: ElevatedButton.styleFrom( // Estilo do botão
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    textStyle: const TextStyle(fontSize: 18),
                    // primary: Colors.deepPurple, // Cor de fundo (deprecated)
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white, // Cor do texto e ícone
                    shape: RoundedRectangleBorder(
                       borderRadius: BorderRadius.circular(8),
                    ),
                 ),
              ),
            ),
            const SizedBox(height: 20), // Espaço inferior
          ],
        ),
      ),
    );
  }

   // Helper para campos de texto (ajustado para validação padrão e tipo)
  Widget _buildTextField(TextEditingController controller, String label, {TextInputType tipo = TextInputType.text, int? maxLines, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      keyboardType: tipo,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: validator ?? (value) { // Usa o validator passado ou um padrão
        if (value == null || value.isEmpty) {
          return 'Por favor, preencha este campo';
        }
         // Validação padrão para números (pode ser mais específica se necessário)
         if (tipo == TextInputType.number) {
            if (double.tryParse(value) == null) {
                return 'Deve ser um número válido';
            }
         }
        return null;
      },
    );
  }

  // Helper para Sexo (ajustado para padding e dense)
  Widget _buildSexoSelector() {
     return InputDecorator( // Usado InputDecorator para dar aparência de campo
       decoration: const InputDecoration(
         labelText: 'Sexo',
         border: OutlineInputBorder(),
         contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Ajuste padding
       ),
       child: Row(
         children: [
           Expanded( // Usado Expanded para que os ListTile ocupem espaço igual
             child: ListTile(
               title: const Text('Macho'),
               leading: Radio<String>(
                 value: 'Macho',
                 groupValue: _sexo,
                 onChanged: (value) {
                   setState(() {
                     _sexo = value!;
                   });
                 },
               ),
                contentPadding: EdgeInsets.zero, // Remove padding interno do ListTile
                dense: true, // Torna o ListTile mais compacto
             ),
           ),
           Expanded(
             child: ListTile(
               title: const Text('Fêmea'),
               leading: Radio<String>(
                 value: 'Fêmea',
                 groupValue: _sexo,
                 onChanged: (value) {
                   setState(() {
                     _sexo = value!;
                   });
                 },
               ),
                contentPadding: EdgeInsets.zero, // Remove padding interno do ListTile
                dense: true, // Torna o ListTile mais compacto
             ),
           ),
         ],
       ),
     );
  }

   // Helper para Porte (ajustado para validator e underline)
  Widget _buildPorteSelector() {
    return DropdownButtonFormField<String>(
      value: _porte,
       // Adicionado underline: Container() para remover a linha padrão se necessário
      decoration: const InputDecoration(
        labelText: 'Porte',
        border: OutlineInputBorder(),
      ),
      items: <String>['Pequeno', 'Médio', 'Grande']
          .map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _porte = newValue!;
        });
      },
       // Adicionado item de dica e validator
       validator: (value) {
          if (value == null || value.isEmpty) {
             return 'Por favor, selecione o porte';
          }
          return null;
       },
    );
  }
}