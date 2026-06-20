import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

  Future<String> obterDeviceId() async {
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id;
    }

    if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? 'ios_desconhecido';
    }

    return 'dispositivo_desconhecido';
  }

  final nomeController = TextEditingController();
  final telefoneController = TextEditingController();
  final emailController = TextEditingController();
  final senhaController = TextEditingController();
  final confirmarSenhaController = TextEditingController();

  bool loading = false;

  @override
  void dispose() {
    nomeController.dispose();
    telefoneController.dispose();
    emailController.dispose();
    senhaController.dispose();
    confirmarSenhaController.dispose();
    super.dispose();
  }

  Future<void> cadastrar() async {
    if (nomeController.text.trim().isEmpty ||
        telefoneController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        senhaController.text.trim().isEmpty ||
        confirmarSenhaController.text.trim().isEmpty) {
      _msg("Preencha todos os campos");
      return;
    }

    if (senhaController.text != confirmarSenhaController.text) {
      _msg("As senhas não coincidem");
      return;
    }

    if (senhaController.text.length < 6) {
      _msg("A senha deve ter pelo menos 6 caracteres");
      return;
    }

    try {
      setState(() => loading = true);

      // 🔥 CRIA USUÁRIO NO AUTH
      final credencial = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: senhaController.text.trim(),
          );

      final uid = credencial.user!.uid;
      final deviceId = await obterDeviceId();
      // 🔥 SALVA NO FIRESTORE
      await FirebaseFirestore.instance.collection('usuarios').doc(uid).set({
        'uid': uid,
        'nome': nomeController.text.trim(),
        'telefone': telefoneController.text.trim(),
        'email': emailController.text.trim(),
        'deviceId': deviceId,
        'dataCadastro': Timestamp.now(),
        'bloqueado': false,
      });

      if (!mounted) return;

      _msg("Conta criada com sucesso!");

      // ❌ NÃO navegar manualmente
      // ✔ AuthCheck vai levar automaticamente pra Home
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          _msg('Este email já está cadastrado.');
          break;

        case 'invalid-email':
          _msg('Email inválido.');
          break;

        case 'weak-password':
          _msg('A senha deve ter pelo menos 6 caracteres.');
          break;

        default:
          _msg(e.message ?? 'Erro ao criar conta.');
      }
    } catch (e) {
      _msg('Erro inesperado: $e');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void _msg(String texto) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Criar Conta"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),

            const Icon(Icons.cake, size: 90, color: Colors.deepPurple),

            const SizedBox(height: 10),

            const Text(
              "Doces da Rita",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),

            const SizedBox(height: 30),

            TextField(
              controller: nomeController,
              decoration: const InputDecoration(
                labelText: "Nome Completo",
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: telefoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "Telefone",
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: "Email",
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: senhaController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Senha",
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: confirmarSenhaController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Confirmar Senha",
                prefixIcon: Icon(Icons.lock_outline),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 25),

            loading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: cadastrar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        "Cadastrar",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
