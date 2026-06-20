import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';
import 'dados_cliente_page.dart';

class CarrinhoPage extends StatefulWidget {
  final Map<String, int> carrinho;
  final List<Produto> produtos;
  final double total;
  final int quantidadeTotal;
  final FirebaseFirestore firestore;
  final VoidCallback onPedidoFinalizado;

  const CarrinhoPage({
    super.key,
    required this.carrinho,
    required this.produtos,
    required this.total,
    required this.quantidadeTotal,
    required this.firestore,
    required this.onPedidoFinalizado,
  });

  @override
  State<CarrinhoPage> createState() => _CarrinhoPageState();
}

class _CarrinhoPageState extends State<CarrinhoPage> {
  late Map<String, int> carrinhoLocal;

  final TextEditingController cupomController = TextEditingController();

  double _percentualCupom = 0;
  double _valorFixoCupom = 0;
  String _tipoCupom = '';

  String? cupomAplicado;
  bool cupomAtivo = false;

  @override
  void initState() {
    super.initState();
    carrinhoLocal = Map<String, int>.from(widget.carrinho);
  }

  /// Devolve o carrinho atualizado para quem chamou esta página
  void _voltarComCarrinho() {
    Navigator.pop(context, Map<String, int>.from(carrinhoLocal));
  }

  Produto getProduto(String id) {
    return widget.produtos.firstWhere(
      (p) => p.id == id,
      orElse: () => Produto(
        id: '',
        nome: 'Produto removido',
        descricao: '',
        preco: 0,
        imagem: '',
      ),
    );
  }

  double get subtotal {
    double soma = 0;
    for (final entry in carrinhoLocal.entries) {
      final p = getProduto(entry.key);
      soma += p.preco * entry.value;
    }
    return soma;
  }

  double get desconto {
    if (!cupomAtivo) return 0;

    if (_tipoCupom == 'percentual') {
      return subtotal * _percentualCupom;
    } else {
      return min(_valorFixoCupom, subtotal);
    }
  }

  double get totalFinal => max(0, subtotal - desconto);

  void removerCupom() {
    setState(() {
      cupomAtivo = false;
      cupomAplicado = null;
      _percentualCupom = 0;
      _valorFixoCupom = 0;
      _tipoCupom = '';
      cupomController.clear();
    });
  }

  void adicionar(String id) {
    setState(() {
      carrinhoLocal[id] = (carrinhoLocal[id] ?? 0) + 1;
    });
  }

  void remover(String id) {
    setState(() {
      final qtd = carrinhoLocal[id] ?? 0;
      if (qtd > 1) {
        carrinhoLocal[id] = qtd - 1;
      } else {
        carrinhoLocal.remove(id);
      }
    });
  }

  Future<void> aplicarCupom() async {
    final codigo = cupomController.text.trim().toUpperCase();
    if (codigo.isEmpty || cupomAtivo) return;

    final query = await FirebaseFirestore.instance
        .collection('cupons')
        .where('codigo', isEqualTo: codigo)
        .where('ativo', isEqualTo: true)
        .get();

    if (query.docs.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cupom inválido')));
      return;
    }

    final doc = query.docs.first;
    final data = doc.data();

    final int usos = (data['usos'] ?? 0);
    final int limite = (data['limiteUsos'] ?? 999999);

    if (usos >= limite) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cupom esgotado')));
      return;
    }

    await FirebaseFirestore.instance.collection('cupons').doc(doc.id).update({
      'usos': FieldValue.increment(1),
      'esgotado': (usos + 1) >= limite,
    });

    setState(() {
      cupomAtivo = true;
      cupomAplicado = codigo;

      if (data['tipo'] == 'percentual') {
        _tipoCupom = 'percentual';
        _percentualCupom = (data['valor'] ?? 0) / 100;
      } else {
        _tipoCupom = 'fixo';
        _valorFixoCupom = (data['valor'] ?? 0).toDouble();
      }
    });
  }

  /// Avisa a HomePage que o pedido foi finalizado (sem fazer pop aqui)
  void finalizarFluxo() {
    widget.onPedidoFinalizado();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // Intercepta o botão físico/gesto de voltar e devolve o carrinho atualizado
      onWillPop: () async {
        _voltarComCarrinho();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Meu Carrinho"),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          // Botão de voltar explícito que devolve o carrinho atualizado
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _voltarComCarrinho,
          ),
        ),

        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: carrinhoLocal.isEmpty
                    ? const Center(child: Text("Carrinho vazio"))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: carrinhoLocal.length,
                        itemBuilder: (context, index) {
                          final id = carrinhoLocal.keys.elementAt(index);
                          final qtd = carrinhoLocal[id]!;
                          final produto = getProduto(id);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: produto.imagem.isNotEmpty
                                    ? Image.network(
                                        produto.imagem,
                                        width: 55,
                                        height: 55,
                                        fit: BoxFit.cover,
                                      )
                                    : const Icon(Icons.cake),
                              ),
                              title: Text(produto.nome),
                              subtitle: Text("R\$ ${produto.preco}"),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove),
                                    onPressed: () => remover(id),
                                  ),
                                  Text("$qtd"),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () => adicionar(id),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),

              /// CUPOM
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: cupomController,
                        enabled: !cupomAtivo,
                        decoration: InputDecoration(
                          labelText: cupomAtivo
                              ? "Cupom: $cupomAplicado"
                              : "Digite o cupom",
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: cupomAtivo ? removerCupom : aplicarCupom,
                      child: Text(cupomAtivo ? "Remover" : "Aplicar"),
                    ),
                  ],
                ),
              ),

              /// TOTAL
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Text("Subtotal: R\$ ${subtotal.toStringAsFixed(2)}"),
                    Text("Desconto: R\$ ${desconto.toStringAsFixed(2)}"),
                    Text(
                      "Total: R\$ ${totalFinal.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ],
                ),
              ),

              /// BOTÃO FINAL
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: carrinhoLocal.isEmpty
                        ? null
                        : () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DadosClientePage(
                                  total: totalFinal,
                                  quantidadeTotal: carrinhoLocal.values.fold(
                                    0,
                                    (a, b) => a + b,
                                  ),
                                  carrinho: carrinhoLocal,
                                  produtos: widget.produtos,
                                  firestore: widget.firestore,
                                  cupom: cupomAplicado,
                                ),
                              ),
                            );
                          },
                    child: const Text("Finalizar Pedido"),
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
