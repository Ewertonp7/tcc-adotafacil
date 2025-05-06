import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:adotafacil/api_config.dart';

class recsenha extends StatefulWidget {
  const recsenha({super.key});

  @override
  _recsenhaState createState() => _recsenhaState();
}

class _recsenhaState extends State<recsenha> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController docController = TextEditingController();
  final TextEditingController codigoController = TextEditingController();
  final TextEditingController novaSenhaController = TextEditingController();
  final TextEditingController confirmarSenhaController = TextEditingController();

  bool isCnpj = false;
  bool _senhaVisivel = false;
  bool _confirmarSenhaVisivel = false;
  bool _codigoEnviado = false;

  @override
  void initState() {
    super.initState();
    _resetarCampos(); // Garantir que os campos estão resetados ao carregar a tela
  }

  // Função para resetar os campos e estados
  void _resetarCampos() {
    emailController.clear();
    docController.clear();
    codigoController.clear();
    novaSenhaController.clear();
    confirmarSenhaController.clear();
    setState(() {
      _codigoEnviado = false;
      isCnpj = false;
    });
  }

  void _mostrarMensagem(String mensagem) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Aviso"),
        content: Text(mensagem),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> _enviarCodigo() async {
    String email = emailController.text.trim();
    String documento = docController.text.trim();

    if (email.isEmpty || documento.isEmpty) {
      _mostrarMensagem("Preencha o e-mail e CPF/CNPJ.");
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/recuperar-senha/enviar-codigo'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "documento": documento,
          "isCnpj": isCnpj,
        }),
      );
      final json = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          _codigoEnviado = true;
        });
        _mostrarMensagem("Código enviado para seu e-mail.");
      } else {
        _mostrarMensagem(json["erro"] ?? "Erro ao enviar o código.");
      }
    } catch (e) {
      _mostrarMensagem("Erro: $e");
    }
  }

  Future<void> _alterarSenha() async {
    String email = emailController.text.trim();
    String codigo = codigoController.text.trim();
    String novaSenha = novaSenhaController.text;
    String confirmarSenha = confirmarSenhaController.text;

    if (codigo.isEmpty || novaSenha.isEmpty || confirmarSenha.isEmpty) {
      _mostrarMensagem("Preencha todos os campos.");
      return;
    }

    if (novaSenha.length < 6) {
      _mostrarMensagem("A senha deve ter no mínimo 6 caracteres.");
      return;
    }

    if (novaSenha != confirmarSenha) {
      _mostrarMensagem("As senhas não coincidem.");
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/recuperar-senha/confirmarCodigo'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "codigo": codigo,
          "novaSenha": novaSenha,
        }),
      );

      final json = jsonDecode(response.body);
      if (response.statusCode == 200) {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Sucesso"),
            content: const Text("Senha alterada com sucesso."),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(), // fecha o alerta
                child: const Text("OK"),
              ),
            ],
          ),
        );

        Navigator.pop(context); // só sai da tela depois que fechar o alerta
      } else {
        _mostrarMensagem(json["erro"] ?? "Erro ao alterar senha.");
      }
    } catch (e) {
      _mostrarMensagem("Erro: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.pink),
          onPressed: () {
            _resetarCampos(); // Limpa os campos ao voltar
            Navigator.pop(context);
          },
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).requestFocus(FocusNode()), // Fecha o teclado ao tocar fora dos campos
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'Recuperação de Senha',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.pink,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Campos da primeira etapa
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'E-mail',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                enabled: !_codigoEnviado,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: docController,
                decoration: InputDecoration(
                  labelText: isCnpj ? 'CNPJ' : 'CPF',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                keyboardType: TextInputType.number,
                enabled: !_codigoEnviado,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Checkbox(
                    value: isCnpj,
                    onChanged: _codigoEnviado
                        ? null
                        : (value) {
                            setState(() {
                              isCnpj = value!;
                            });
                          },
                  ),
                  const Text('CNPJ?'),
                ],
              ),

              if (_codigoEnviado) ...[
                const SizedBox(height: 20),
                TextField(
                  controller: codigoController,
                  decoration: InputDecoration(
                    labelText: 'Código de Verificação',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: novaSenhaController,
                  obscureText: !_senhaVisivel,
                  decoration: InputDecoration(
                    labelText: 'Nova Senha',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _senhaVisivel ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _senhaVisivel = !_senhaVisivel;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: confirmarSenhaController,
                  obscureText: !_confirmarSenhaVisivel,
                  decoration: InputDecoration(
                    labelText: 'Confirme a Nova Senha',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _confirmarSenhaVisivel ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _confirmarSenhaVisivel = !_confirmarSenhaVisivel;
                        });
                      },
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 30),
              Center(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _codigoEnviado ? _alterarSenha : _enviarCodigo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 0, 37, 116),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    child: Text(
                      _codigoEnviado ? 'Alterar Senha' : 'Enviar Código',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}