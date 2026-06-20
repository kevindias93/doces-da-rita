import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../pages/acompanhamento_page.dart';
import '../models/cliente.dart';
import 'cartao_page.dart';

class PagamentoPage extends StatefulWidget {
  final double total;
  final int quantidadeTotal;
  final Map<String, int> carrinho;
  final List<dynamic> produtos;
  final FirebaseFirestore firestore;
  final Cliente cliente;
  final String clienteId;
  final String? cupom;
  final VoidCallback onPedidoFinalizado;

  const PagamentoPage({
    super.key,
    required this.total,
    required this.quantidadeTotal,
    required this.carrinho,
    required this.produtos,
    required this.firestore,
    required this.cliente,
    required this.clienteId,
    required this.onPedidoFinalizado,
    this.cupom,
  });

  @override
  State<PagamentoPage> createState() => _PagamentoPageState();
}

class _PagamentoPageState extends State<PagamentoPage> {
  String formaPagamento = "PIX";
  bool _processando = false;

  Future<String> salvarPedido(String pagamento) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception("Usuário não logado");
    }

    final itens = widget.carrinho.entries.map((entry) {
      final produto = widget.produtos.firstWhere((p) => p.id == entry.key);
      return {
        "id": produto.id,
        "nome": produto.nome,
        "quantidade": entry.value,
        "preco": produto.preco,
        "subtotal": produto.preco * entry.value,
      };
    }).toList();

    final statusPagamento = (pagamento == "PIX" || pagamento == "CARTAO")
        ? "Aguardando pagamento"
        : "Pagamento na entrega";

    final docRef = await widget.firestore.collection("pedidos").add({
      "userId": user.uid,
      "clienteId": widget.clienteId,
      "cliente": widget.cliente.nome,
      "telefone": widget.cliente.telefone,
      "endereco": widget.cliente.endereco,
      "numero": widget.cliente.numero,
      "bairro": widget.cliente.bairro,
      "complemento": widget.cliente.complemento,
      "observacao": widget.cliente.observacao,
      "itens": itens,
      "total": widget.total,
      "pagamento": pagamento,
      "statusPagamento": statusPagamento,
      "statusPedido": "Pendente",
      "cupom": widget.cupom,
      "data": Timestamp.now(),
    });

    return docRef.id;
  }

  Future<Map<String, dynamic>> gerarPix(String pedidoId) async {
    final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
    final callable = functions.httpsCallable('criarPixAsaas');

    final result = await callable.call({
      'valor': widget.total,
      'nome': widget.cliente.nome,
      'pedidoId': pedidoId,
    });

    return Map<String, dynamic>.from(result.data);
  }

  Future<void> mostrarPix(Map<String, dynamic> pixData, String pedidoId) async {
    if (!mounted) return;

    final String? base64Str = pixData["qrCode"];
    Uint8List? qrBytes;

    if (base64Str != null) {
      final String base64Data = base64Str.contains(',')
          ? base64Str.split(',')[1]
          : base64Str;
      qrBytes = base64Decode(base64Data);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "PIX Gerado",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              if (qrBytes != null) Image.memory(qrBytes, height: 220),
              const SizedBox(height: 20),
              SelectableText(
                pixData["pixCopiaECola"] ?? "",
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AcompanhamentoPage(pedidoId: pedidoId),
                    ),
                  );
                },
                child: const Text("Já realizei o pagamento"),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> finalizarPagamento() async {
    if (_processando) return;

    setState(() => _processando = true);

    try {
      if (formaPagamento == "PIX") {
        final pedidoId = await salvarPedido("PIX");
        widget.onPedidoFinalizado();
        final pixData = await gerarPix(pedidoId);
        await mostrarPix(pixData, pedidoId);
        return;
      }

      if (formaPagamento == "CARTAO") {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CartaoPage(
              total: widget.total,
              nome: widget.cliente.nome,
              clienteId: widget.clienteId,
              onConfirmar: (dados) async {
                final pedidoId = await salvarPedido("CARTAO");
                widget.onPedidoFinalizado();
                if (!mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AcompanhamentoPage(pedidoId: pedidoId),
                  ),
                );
              },
            ),
          ),
        );
        return;
      }

      // ENTREGA
      final pedidoId = await salvarPedido("ENTREGA");
      widget.onPedidoFinalizado();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AcompanhamentoPage(pedidoId: pedidoId),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erro: $e")));
      }
    } finally {
      if (mounted) setState(() => _processando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pagamento")),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                "Total: R\$ ${widget.total.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              RadioListTile<String>(
                title: const Text("PIX"),
                value: "PIX",
                groupValue: formaPagamento,
                onChanged: _processando
                    ? null
                    : (value) => setState(() => formaPagamento = value!),
              ),
              RadioListTile<String>(
                title: const Text("Cartão"),
                value: "CARTAO",
                groupValue: formaPagamento,
                onChanged: _processando
                    ? null
                    : (value) => setState(() => formaPagamento = value!),
              ),
              RadioListTile<String>(
                title: const Text("Pagar na Entrega"),
                value: "ENTREGA",
                groupValue: formaPagamento,
                onChanged: _processando
                    ? null
                    : (value) => setState(() => formaPagamento = value!),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _processando ? null : finalizarPagamento,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _processando
                      ? const CircularProgressIndicator()
                      : const Text("Confirmar", style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
