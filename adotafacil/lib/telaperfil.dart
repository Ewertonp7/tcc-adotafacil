import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'telahome.dart';
import 'telaacesso.dart';
import 'package:adotafacil/api_config.dart';
import 'image_viewer_screen.dart';


class TelaPerfil extends StatefulWidget {
  const TelaPerfil({super.key});

  @override
  State<TelaPerfil> createState() => _TelaPerfilState();
}

class _TelaPerfilState extends State<TelaPerfil> {
  File? _imagemPerfil;
  final ImagePicker _picker = ImagePicker();
  String imagemUrl = '';

  final TextEditingController nomeController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController telefoneController = TextEditingController();
  final TextEditingController senhaController = TextEditingController();

  bool modoEdicaoAtivo = false;
  bool houveAlteracoes = false;
  bool senhaVisivel = false;

  @override
  void initState() {
    super.initState();
    _carregarDadosUsuario();
  }

Future<void> _carregarDadosUsuario() async {
  final prefs = await SharedPreferences.getInstance();
  final idUsuario = prefs.getInt('id_usuario');

  debugPrint('🔎 ID do usuário armazenado: $idUsuario');

  if (idUsuario == null) {
    debugPrint('⚠️ ID do usuário não encontrado. Redirecionando para TelaAcesso.');
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const TelaAcesso()),
      );
    }
    return;
  }

  final url = Uri.parse('${ApiConfig.baseUrl}/api/usuarios/$idUsuario');
  debugPrint('📡 Fazendo requisição para: $url');

  try {
    final response = await http.get(url);

    debugPrint('✅ Resposta recebida com status: ${response.statusCode}');
    debugPrint('📦 Corpo da resposta: ${response.body}');

    if (response.statusCode == 200) {
      final dados = json.decode(response.body);

      setState(() {
        nomeController.text = dados['nome'] ?? '';
        emailController.text = dados['email'] ?? '';
        telefoneController.text = dados['telefone'] ?? '';
        senhaController.text = '';
        imagemUrl = dados['imagem_url'] ?? '';
      });

      debugPrint('✅ Dados do usuário carregados com sucesso.');
    } else {
      debugPrint('❌ Falha ao carregar dados. Status: ${response.statusCode}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ${response.statusCode}: Não foi possível carregar os dados do usuário')),
      );
    }
  } catch (e) {
    debugPrint('💥 Erro ao carregar dados do usuário: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Erro de conexão ao carregar os dados')),
    );
  }
}
  bool _emailValido(String email) {
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return regex.hasMatch(email);
  }

  Future<void> _atualizarDadosUsuario() async {
  final prefs = await SharedPreferences.getInstance();
  final idUsuario = prefs.getInt('id_usuario');

  final email = emailController.text.trim();
  if (!_emailValido(email)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('E-mail inválido')),
    );
    return;
  }

  final body = json.encode({
    "nome": nomeController.text,
    "email": email,
    "telefone": telefoneController.text,
    "senha": senhaController.text.isNotEmpty ? senhaController.text : null,
    "imagem_url": imagemUrl,
  });

  final response = await http.put(
    Uri.parse('${ApiConfig.baseUrl}/api/usuarios/$idUsuario'),
    headers: {"Content-Type": "application/json"},
    body: body,
  );

  if (response.statusCode == 200) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Dados atualizados com sucesso!')),
    );
  } else if (response.statusCode == 409) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Este e-mail já está em uso')),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Erro ao atualizar os dados')),
    );
  }
}


  Future<String?> uploadImagemParaAzure(File imagem) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final idUsuario = prefs.getInt('id_usuario');
      if (idUsuario == null) return null;

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/api/usuarios/$idUsuario/imagem'),
      );
      request.files.add(await http.MultipartFile.fromPath('imagem', imagem.path));
      final response = await request.send();

      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final data = json.decode(respStr);
        return data['imagem_url'];
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('Erro ao enviar imagem: $e');
      return null;
    }
  }

  Future<File?> _cropImage(File imageFile) async {
    try {
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Editar Imagem',
            toolbarColor: Colors.pink,
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: Colors.purple,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
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
    return null;
  }


  Future<void> _selecionarImagem() async {
     showModalBottomSheet(
       context: context,
       builder: (context) => Wrap(
         children: [
           ListTile(
             leading: const Icon(Icons.photo_library),
             title: const Text('Selecionar da Galeria'),
             onTap: () async {
               Navigator.pop(context);
               final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
               if (pickedFile != null) {
                 File imageFile = File(pickedFile.path);
                 File? croppedFile = await _cropImage(imageFile);
                 if (croppedFile != null) {
                   final url = await uploadImagemParaAzure(croppedFile);
                   if (url != null) {
                     setState(() {
                       _imagemPerfil = croppedFile;
                       imagemUrl = url;
                       houveAlteracoes = true;
                     });
                   } else {
                     ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(content: Text('Erro ao enviar imagem')),
                     );
                   }
                 }
               }
             },
           ),
           ListTile(
             leading: const Icon(Icons.camera_alt),
             title: const Text('Tirar Foto'),
             onTap: () async {
               Navigator.pop(context);
               final pickedFile = await _picker.pickImage(source: ImageSource.camera);
                if (pickedFile != null) {
                 File imageFile = File(pickedFile.path);
                 File? croppedFile = await _cropImage(imageFile);
                 if (croppedFile != null) {
                   final url = await uploadImagemParaAzure(croppedFile);
                   if (url != null) {
                     setState(() {
                       _imagemPerfil = croppedFile;
                       imagemUrl = url;
                       houveAlteracoes = true;
                     });
                   } else {
                     ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(content: Text('Erro ao enviar imagem')),
                     );
                   }
                 }
               }
             },
           ),
         ],
       ),
     );
  }


  void _confirmarAlteracoes() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Deseja confirmar as alterações?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Não", style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _atualizarDadosUsuario();
                setState(() {
                  houveAlteracoes = false;
                  modoEdicaoAtivo = false;
                });
              },
              child: const Text("Sim", style: TextStyle(color: Colors.green)),
            ),
          ],
        );
      },
    );
  }

  void _confirmarLogout() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Deseja sair da conta?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('id_usuario');
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const TelaAcesso()),
                    (Route<dynamic> route) => false,
                  );
                }
              },
              child: const Text("Sair"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCampoTexto(String label, TextEditingController controller, {bool isSenha = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          enabled: modoEdicaoAtivo,
          obscureText: isSenha && !senhaVisivel,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            filled: true,
            fillColor: Colors.grey[100],
            suffixIcon: isSenha
                ? IconButton(
                    icon: Icon(
                      senhaVisivel ? Icons.visibility : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        senhaVisivel = !senhaVisivel;
                      });
                    },
                  )
                : null,
          ),
          onChanged: (_) => setState(() => houveAlteracoes = true),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determina a fonte da imagem a ser exibida (File se selecionada, URL se salva, ou nulo)
    final ImageProvider<Object>? currentImageProvider = _imagemPerfil != null
        ? FileImage(_imagemPerfil!)
        : (imagemUrl.isNotEmpty ? NetworkImage(imagemUrl) : null);

    // Determina a source string para visualização em tela cheia
    // Usamos a URL salva se existir, caso contrário, o caminho do arquivo selecionado temporariamente
    // Só criamos a string source se houver alguma imagem para exibir
    final String? viewerImageSource = (imagemUrl.isNotEmpty) ? imagemUrl : (_imagemPerfil != null ? _imagemPerfil!.path : null);


    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.pink),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const TelaHome()),
          ),
        ),
        title: const Text("Meu Perfil", style: TextStyle(fontWeight: FontWeight.bold,
              color: Colors.pink)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: _confirmarLogout,
          ),
          IconButton(
            icon: Icon(modoEdicaoAtivo ? Icons.save : Icons.edit, color: Colors.purple),
            onPressed: () {
              setState(() {
                if (modoEdicaoAtivo) {
                  _confirmarAlteracoes();
                } else {
                  modoEdicaoAtivo = true;
                }
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          children: [
            // GestureDetector para selecionar (modo edição) ou visualizar (modo estático)
            // Apenas clicável se houver uma imagem para exibir
            GestureDetector(
              onTap: (viewerImageSource != null) ? () { // Clicável SE houver imagem
                if (modoEdicaoAtivo) {
                   // No modo edição, clica para selecionar nova imagem
                   _selecionarImagem();
                } else {
                   // No modo estático, clica para visualizar a imagem em tela cheia
                   Navigator.push(
                     context,
                     MaterialPageRoute(
                       builder: (context) => ImageViewerScreen(imageSource: viewerImageSource),
                     ),
                   );
                }
              } : null, // onTap é null se não houver imagem
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey.shade300,
                backgroundImage: currentImageProvider,
                child: currentImageProvider == null
                    ? const Icon(Icons.person, size: 60, color: Colors.grey)
                    : null,
              ),
            ),
            const SizedBox(height: 30),
            _buildCampoTexto("Nome", nomeController),
            const SizedBox(height: 20),
            _buildCampoTexto("E-mail", emailController),
            const SizedBox(height: 20),
            _buildCampoTexto("Telefone", telefoneController),
            const SizedBox(height: 20),
            _buildCampoTexto("Senha", senhaController, isSenha: true),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: houveAlteracoes && modoEdicaoAtivo ? _confirmarAlteracoes : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                 foregroundColor: Colors.white,
              ),
              child: const Text("Salvar dados"),
            ),
          ],
        ),
      ),
    );
  }
}