import 'package:flutter/material.dart';
import '../main.dart';

class ProdutoDetalhePage extends StatelessWidget {
  final Produto produto;
  final Function(Produto) adicionarProduto;

  const ProdutoDetalhePage({
    super.key,
    required this.produto,
    required this.adicionarProduto,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),

                // 🔹 barrinha de arrastar
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // 🔹 conteúdo scrollável
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        produto.imagem.isNotEmpty
                            ? Image.network(
                                produto.imagem,
                                width: double.infinity,
                                height: 300,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                height: 300,
                                color: Colors.deepPurple.shade100,
                                child: const Center(
                                  child: Icon(Icons.cake, size: 100),
                                ),
                              ),

                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                produto.nome,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 12),

                              Text(
                                produto.descricao,
                                style: const TextStyle(fontSize: 16),
                              ),

                              const SizedBox(height: 20),

                              Text(
                                "R\$ ${produto.preco.toStringAsFixed(2)}",
                                style: const TextStyle(
                                  fontSize: 24,
                                  color: Colors.deepPurple,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 🔹 botão fixo
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () {
                        adicionarProduto(produto);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "${produto.nome} adicionado ao carrinho",
                            ),
                          ),
                        );

                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.shopping_cart),
                      label: const Text("Adicionar ao Carrinho"),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
