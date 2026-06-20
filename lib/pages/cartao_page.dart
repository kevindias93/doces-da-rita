import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';

class CartaoPage extends StatefulWidget {
  final double total;
  final String nome;
  final String clienteId;
  final Function(Map<String, dynamic>) onConfirmar;

  const CartaoPage({
    super.key,
    required this.total,
    required this.nome,
    required this.clienteId,
    required this.onConfirmar,
  });

  @override
  State<CartaoPage> createState() => _CartaoPageState();
}

class _CartaoPageState extends State<CartaoPage> {
  final numeroController = TextEditingController();
  final nomeController = TextEditingController();
  final validadeController = TextEditingController();
  final cvvController = TextEditingController();
  final cpfController = TextEditingController();

  bool carregando = false;

  Future<void> confirmar() async {
    if (numeroController.text.isEmpty ||
        nomeController.text.isEmpty ||
        validadeController.text.isEmpty ||
        cvvController.text.isEmpty ||
        cpfController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preencha todos os dados do cartão")),
      );
      return;
    }

    setState(() => carregando = true);

    try {
      final validade = validadeController.text.split('/');
      final mes = validade[0].trim();
      final ano = validade.length > 1 ? validade[1].trim() : '';

      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      final callable = functions.httpsCallable('criarCartaoAsaas');

      final result = await callable.call({
        'valor': widget.total,
        'nome': widget.nome,
        'cpfCnpj': cpfController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        'clienteId': widget.clienteId,
        'cartao': {
          'numero': numeroController.text.replaceAll(RegExp(r'[^0-9]'), ''),
          'nome': nomeController.text,
          'mes': mes,
          'ano': '20$ano',
          'cvv': cvvController.text,
        },
      });

      setState(() => carregando = false);

      widget.onConfirmar(Map<String, dynamic>.from(result.data));
    } catch (e) {
      setState(() => carregando = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erro: $e")));
      }
    }
  }

  @override
  void dispose() {
    numeroController.dispose();
    nomeController.dispose();
    validadeController.dispose();
    cvvController.dispose();
    cpfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cartão de Crédito"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Total: R\$ ${widget.total.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: numeroController,
                keyboardType: TextInputType.number,
                maxLength: 19,
                decoration: const InputDecoration(
                  labelText: "Número do cartão",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: nomeController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: "Nome no cartão",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: validadeController,
                      keyboardType: TextInputType.datetime,
                      decoration: const InputDecoration(
                        labelText: "Validade (MM/AA)",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: cvvController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 4,
                      decoration: const InputDecoration(
                        labelText: "CVV",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              TextField(
                controller: cpfController,
                keyboardType: TextInputType.number,
                maxLength: 14,
                decoration: const InputDecoration(
                  labelText: "CPF do titular",
                  border: OutlineInputBorder(),
                  hintText: "000.000.000-00",
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: carregando ? null : confirmar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: carregando
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Confirmar Pagamento"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
