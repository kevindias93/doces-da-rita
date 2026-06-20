import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import '../models/cliente.dart';
import '../pages/pagamento_page.dart';
import '../main.dart';

class DadosClientePage extends StatefulWidget {
  final double total;
  final int quantidadeTotal;
  final Map<String, int> carrinho;
  final List<Produto> produtos;
  final FirebaseFirestore firestore;
  final String? cupom;

  const DadosClientePage({
    super.key,
    required this.total,
    required this.quantidadeTotal,
    required this.carrinho,
    required this.produtos,
    required this.firestore,
    this.cupom,
  });

  @override
  State<DadosClientePage> createState() => _DadosClientePageState();
}

class _DadosClientePageState extends State<DadosClientePage> {
  final nomeController = TextEditingController();
  final telefoneController = TextEditingController();
  final enderecoController = TextEditingController();
  final numeroController = TextEditingController();
  final bairroController = TextEditingController();
  final complementoController = TextEditingController();
  final observacaoController = TextEditingController();

  String? clienteId;
  bool carregando = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _initClienteId();
    await _carregarUsuario();
  }

  Future<void> _initClienteId() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      clienteId = user.uid;
    } else {
      clienteId = const Uuid().v4();
    }

    setState(() {});
  }

  Future<void> _carregarUsuario() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .get();

    if (!doc.exists) return;

    final data = doc.data()!;
    nomeController.text = data['nome'] ?? '';
    telefoneController.text = data['telefone'] ?? '';
  }

  bool validar() {
    return nomeController.text.isNotEmpty &&
        telefoneController.text.isNotEmpty &&
        enderecoController.text.isNotEmpty &&
        numeroController.text.isNotEmpty;
  }

  void continuar() {
    if (!validar()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preencha os campos obrigatórios")),
      );
      return;
    }

    if (clienteId == null) return;

    final cliente = Cliente(
      nome: nomeController.text,
      telefone: telefoneController.text,
      endereco: enderecoController.text,
      numero: numeroController.text,
      bairro: bairroController.text,
      complemento: complementoController.text,
      observacao: observacaoController.text,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PagamentoPage(
          total: widget.total,
          quantidadeTotal: widget.quantidadeTotal,
          carrinho: widget.carrinho,
          produtos: widget.produtos,
          firestore: widget.firestore,
          cliente: cliente,
          clienteId: clienteId!,
          cupom: widget.cupom,
          onPedidoFinalizado: () {},
        ),
      ),
    );
  }

  @override
  void dispose() {
    nomeController.dispose();
    telefoneController.dispose();
    enderecoController.dispose();
    numeroController.dispose();
    bairroController.dispose();
    complementoController.dispose();
    observacaoController.dispose();
    super.dispose();
  }

  InputDecoration dec(String label) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dados do Cliente")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: nomeController, decoration: dec("Nome *")),
            const SizedBox(height: 12),
            TextField(
              controller: telefoneController,
              decoration: dec("Telefone *"),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: enderecoController,
              decoration: dec("Endereço *"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: numeroController,
              decoration: dec("Número *"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(controller: bairroController, decoration: dec("Bairro")),
            const SizedBox(height: 12),
            TextField(
              controller: complementoController,
              decoration: dec("Complemento"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: observacaoController,
              decoration: dec("Observação"),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: continuar,
                child: const Text("Continuar"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
