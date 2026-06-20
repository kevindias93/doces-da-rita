import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'admin_produtos_page.dart';
import 'dashboard_page.dart';
import 'admin_cupons_page.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  String filtroStatus = "Todos";

  static const List<String> statusList = [
    'Pendente',
    'Em Produção',
    'Saiu para Entrega',
    'Entregue',
    'Cancelado',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel Administrativo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.card_giftcard),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminCuponsPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.dashboard),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DashboardPage()),
              );
            },
          ),
        ],
      ),

      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: "cupons",
            backgroundColor: Colors.orange,
            icon: const Icon(Icons.card_giftcard),
            label: const Text('Cupons'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminCuponsPage()),
              );
            },
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: "produtos",
            backgroundColor: Colors.deepPurple,
            icon: const Icon(Icons.cake),
            label: const Text('Produtos'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminProdutosPage()),
              );
            },
          ),
        ],
      ),

      body: Column(
        children: [
          // 🔎 FILTRO
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<String>(
              value: filtroStatus,
              items: [
                const DropdownMenuItem(value: "Todos", child: Text("Todos")),
                ...statusList.map(
                  (status) =>
                      DropdownMenuItem(value: status, child: Text(status)),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  filtroStatus = value!;
                });
              },
              decoration: const InputDecoration(
                labelText: "Filtrar pedidos",
                border: OutlineInputBorder(),
              ),
            ),
          ),

          // 📦 LISTA
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: firestore
                  .collection('pedidos')
                  .orderBy('data', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final pedidos = snapshot.data!.docs;

                final filtrados = pedidos.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final status = data['statusPedido'] ?? 'Pendente';

                  return filtroStatus == "Todos" || status == filtroStatus;
                }).toList();

                if (filtrados.isEmpty) {
                  return const Center(child: Text("Nenhum pedido encontrado"));
                }

                return ListView.builder(
                  itemCount: filtrados.length,
                  itemBuilder: (context, index) {
                    final doc = filtrados[index];
                    final pedido = doc.data() as Map<String, dynamic>;

                    final itens = pedido['itens'] as List? ?? [];

                    final statusPedido = pedido['statusPedido'] ?? 'Pendente';

                    final statusPagamento =
                        pedido['statusPagamento'] ?? 'Aguardando pagamento';

                    final cliente = pedido['cliente'] ?? 'Cliente';

                    final userId = pedido['userId'] ?? '';

                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 👤 CLIENTE
                            Text(
                              cliente,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            Text("UserID: $userId"),

                            const SizedBox(height: 8),

                            Text("Pagamento: ${pedido['pagamento'] ?? ''}"),
                            Text("Status pagamento: $statusPagamento"),
                            Text("Status pedido: $statusPedido"),

                            const SizedBox(height: 10),

                            const Text(
                              "Itens:",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),

                            const SizedBox(height: 5),

                            ...itens.map((item) {
                              return Text(
                                "- ${item['nome']} x${item['quantidade']}",
                              );
                            }),

                            const SizedBox(height: 10),

                            // 🔄 STATUS PEDIDO
                            DropdownButton<String>(
                              value: statusList.contains(statusPedido)
                                  ? statusPedido
                                  : "Pendente",
                              items: statusList.map((status) {
                                return DropdownMenuItem(
                                  value: status,
                                  child: Text(status),
                                );
                              }).toList(),
                              onChanged: (novoStatus) async {
                                if (novoStatus == null) return;

                                await firestore
                                    .collection('pedidos')
                                    .doc(doc.id)
                                    .update({'statusPedido': novoStatus});
                              },
                            ),

                            const SizedBox(height: 10),

                            Text(
                              "Total: R\$ ${pedido['total']}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
