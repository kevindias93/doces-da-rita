import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('pedidos').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final pedidos = snapshot.data!.docs;

          int totalPedidos = pedidos.length;

          int novos = 0;
          int producao = 0;
          int entrega = 0;
          int entregues = 0;
          int cancelados = 0;

          double valorTotal = 0;

          for (var doc in pedidos) {
            final pedido = doc.data() as Map<String, dynamic>;

            final status = pedido['status'] ?? '';
            valorTotal += (pedido['total'] ?? 0).toDouble();

            switch (status) {
              case 'Novo':
                novos++;
                break;

              case 'Em Produção':
                producao++;
                break;

              case 'Saiu para Entrega':
                entrega++;
                break;

              case 'Entregue':
                entregues++;
                break;

              case 'Cancelado':
                cancelados++;
                break;
            }
          }

          return Padding(
            padding: const EdgeInsets.all(16),

            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,

              children: [
                _card("Pedidos", totalPedidos.toString(), Icons.shopping_bag),

                _card(
                  "Vendas",
                  "R\$ ${valorTotal.toStringAsFixed(2)}",
                  Icons.attach_money,
                ),

                _card("🟡 Novos", novos.toString(), Icons.fiber_new),

                _card("🟠 Produção", producao.toString(), Icons.build),

                _card("🚚 Entrega", entrega.toString(), Icons.local_shipping),

                _card("✅ Entregues", entregues.toString(), Icons.check_circle),

                _card("❌ Cancelados", cancelados.toString(), Icons.cancel),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _card(String titulo, String valor, IconData icone) {
    return Card(
      elevation: 4,

      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icone, size: 40, color: Colors.deepPurple),

            const SizedBox(height: 10),

            Text(
              valor,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 5),

            Text(titulo),
          ],
        ),
      ),
    );
  }
}
