import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:adotafacil/api_config.dart';

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final TextEditingController nomeController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController telefoneController = TextEditingController();
  final TextEditingController cpfController = TextEditingController();
  final TextEditingController senhaController = TextEditingController();
  final TextEditingController confirmarSenhaController = TextEditingController();

  bool isCnpj = false;
  bool _senhaVisivel = false;
  bool _confirmarSenhaVisivel = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.pink, size: 30),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              const Center(
                child: Text(
                  "Bem-Vindo!",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.pink,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildTextField("Nome", nomeController),
              const SizedBox(height: 16),
              _buildTextField("E-mail", emailController, isEmail: true),
              const SizedBox(height: 16),
              _buildTextField("Telefone", telefoneController),
              const SizedBox(height: 16),
              _buildTextField(isCnpj ? "CNPJ" : "CPF", cpfController),
              const SizedBox(height: 16),
              Row(
                children: [
                  Transform.scale(
                    scale: 1.3,
                    child: Checkbox(
                      value: isCnpj,
                      onChanged: (value) {
                        setState(() {
                          isCnpj = value!;
                        });
                      },
                    ),
                  ),
                  const Text(
                    "CNPJ?",
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField("Senha", senhaController, isPassword: true),
              const SizedBox(height: 16),
              _buildTextField("Confirme sua Senha", confirmarSenhaController, isPassword: true),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 0, 37, 116),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  onPressed: _cadastrarUsuario,
                  child: const Text(
                    "Criar Conta",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool isPassword = false, bool isEmail = false}) {
    bool isConfirmarSenha = label.toLowerCase().contains("confirme");
    bool mostrarSenha = isConfirmarSenha ? _confirmarSenhaVisivel : _senhaVisivel;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? !mostrarSenha : false,
        keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Colors.purple),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Colors.purple),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Colors.deepPurple),
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    mostrarSenha ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      if (isConfirmarSenha) {
                        _confirmarSenhaVisivel = !_confirmarSenhaVisivel;
                      } else {
                        _senhaVisivel = !_senhaVisivel;
                      }
                    });
                  },
                )
              : null,
        ),
      ),
    );
  }

  void _showDialog(String mensagem) {
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

  Future<void> _cadastrarUsuario() async {
    String nome = nomeController.text.trim();
    String email = emailController.text.trim();
    String telefone = telefoneController.text.trim();
    String documento = cpfController.text.trim(); // pode ser CPF ou CNPJ
    String senha = senhaController.text;
    String confirmarSenha = confirmarSenhaController.text;

    if (nome.isEmpty || email.isEmpty || telefone.isEmpty || documento.isEmpty || senha.isEmpty || confirmarSenha.isEmpty) {
      _showDialog("Preencha todos os campos obrigatórios.");
      return;
    }

    if (senha != confirmarSenha) {
      _showDialog("As senhas não coincidem.");
      return;
    }

    if (isCnpj && documento.length != 14) {
      _showDialog("O CNPJ deve conter 14 dígitos.");
      return;
    } else if (!isCnpj && documento.length != 11) {
      _showDialog("O CPF deve conter 11 dígitos.");
      return;
    }

    var body = {
      "nome": nome,
      "email": email,
      "telefone": telefone,
      "senha": senha,
      if (isCnpj) "cnpj": documento else "cpf": documento,
    };

    try {
      var response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/api/auth/cadastrar"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      var jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 201) {
        _showDialog("Usuário cadastrado com sucesso.");
      } else {
        _showDialog(jsonResponse['error'] ?? "Erro ao cadastrar.");
      }
    } catch (e) {
      _showDialog("Erro de conexão: $e");
    }
  }
}