import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'cadastro_page.dart';
import 'termos_uso_page.dart';
import 'politica_privacidade_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final senha = TextEditingController();

  bool loading = false;

  @override
  void dispose() {
    email.dispose();
    senha.dispose();
    super.dispose();
  }

  Future<void> login() async {
    try {
      setState(() => loading = true);

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.text.trim(),
        password: senha.text.trim(),
      );

      if (!mounted) return;

      // NÃO FAZ NADA AQUI
    } on FirebaseAuthException catch (e) {
      String mensagem;

      switch (e.code) {
        case 'invalid-email':
          mensagem = "E-mail inválido.";
          break;

        case 'user-not-found':
          mensagem = "Usuário não encontrado.";
          break;

        case 'wrong-password':
          mensagem = "Senha incorreta.";
          break;

        case 'user-disabled':
          mensagem = "Esta conta foi desativada.";
          break;

        case 'too-many-requests':
          mensagem = "Muitas tentativas. Tente novamente mais tarde.";
          break;

        case 'network-request-failed':
          mensagem = "Sem conexão com a internet.";
          break;

        case 'invalid-credential':
          mensagem = "E-mail ou senha inválidos.";
          break;

        default:
          mensagem = "Erro ao fazer login.";
      }

      _msg(mensagem);
    } catch (_) {
      _msg("Erro inesperado. Tente novamente.");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> recuperarSenha() async {
    if (email.text.trim().isEmpty) {
      _msg("Digite seu email primeiro");
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email.text.trim(),
      );

      _msg("Email de recuperação enviado!");
    } on FirebaseAuthException catch (e) {
      _msg(e.message ?? "Erro ao recuperar senha");
    }
  }

  void _msg(String texto) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple, Colors.pink],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              margin: const EdgeInsets.all(20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 12,
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cake, size: 60, color: Colors.deepPurple),

                    const SizedBox(height: 10),

                    const Text(
                      "Doces da Rita",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    TextField(
                      controller: email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: "Email",
                        prefixIcon: const Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    TextField(
                      controller: senha,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "Senha",
                        prefixIcon: const Icon(Icons.lock),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: recuperarSenha,
                        child: const Text("Esqueci minha senha"),
                      ),
                    ),

                    const SizedBox(height: 10),

                    if (loading)
                      const CircularProgressIndicator()
                    else ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text("Entrar"),
                        ),
                      ),

                      const SizedBox(height: 10),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CadastroPage(),
                              ),
                            );
                          },
                          child: const Text("Criar conta"),
                        ),
                      ),

                      const SizedBox(height: 15),

                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const TermosPage(),
                                ),
                              );
                            },
                            child: const Text("Termos de Uso"),
                          ),

                          const Text(" • "),

                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PrivacidadePage(),
                                ),
                              );
                            },
                            child: const Text("Política de Privacidade"),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
