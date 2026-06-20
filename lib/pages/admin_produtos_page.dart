import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/cloudinary_service.dart';

class AdminProdutosPage extends StatefulWidget {
  const AdminProdutosPage({super.key});

  @override
  State<AdminProdutosPage> createState() => _AdminProdutosPageState();
}

class _AdminProdutosPageState extends State<AdminProdutosPage> {
  Future<String?> selecionarEEnviarImagem() async {
    final picker = ImagePicker();

    final arquivo = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (arquivo == null) return null;

    return await CloudinaryService.uploadImagem(File(arquivo.path));
  }

  // 🔥 FUNÇÃO PROMOÇÃO (REGRA: SÓ 1 ATIVA)
  Future<void> definirPromocao(String id) async {
    final firestore = FirebaseFirestore.instance;

    final antigos = await firestore
        .collection('produtos')
        .where('promocao', isEqualTo: true)
        .get();

    for (var doc in antigos.docs) {
      await doc.reference.update({'promocao': false});
    }

    await firestore.collection('produtos').doc(id).update({'promocao': true});

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produto definido como promoção')),
      );
    }
  }

  void editarProduto(
    BuildContext context,
    String id,
    Map<String, dynamic> produto,
  ) {
    final nomeController = TextEditingController(text: produto['nome']);
    final descricaoController = TextEditingController(
      text: produto['descricao'],
    );
    final precoController = TextEditingController(
      text: produto['preco'].toString(),
    );
    final imagemController = TextEditingController(text: produto['imagem']);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar Produto'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomeController,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              TextField(
                controller: descricaoController,
                decoration: const InputDecoration(labelText: 'Descrição'),
              ),
              TextField(
                controller: precoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Preço'),
              ),

              const SizedBox(height: 10),

              ElevatedButton.icon(
                icon: const Icon(Icons.image),
                label: const Text('Selecionar Imagem'),
                onPressed: () async {
                  final url = await selecionarEEnviarImagem();

                  if (url != null) {
                    imagemController.text = url;

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Imagem enviada com sucesso'),
                        ),
                      );
                    }
                  }
                },
              ),

              const SizedBox(height: 10),

              TextField(
                controller: imagemController,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Imagem'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('produtos')
                  .doc(id)
                  .update({
                    'nome': nomeController.text,
                    'descricao': descricaoController.text,
                    'preco': double.tryParse(precoController.text) ?? 0,
                    'imagem': imagemController.text,
                  });

              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void adicionarProduto(BuildContext context) {
    final nomeController = TextEditingController();
    final descricaoController = TextEditingController();
    final precoController = TextEditingController();
    final imagemController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Novo Produto'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomeController,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              TextField(
                controller: descricaoController,
                decoration: const InputDecoration(labelText: 'Descrição'),
              ),
              TextField(
                controller: precoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Preço'),
              ),

              const SizedBox(height: 10),

              ElevatedButton.icon(
                icon: const Icon(Icons.image),
                label: const Text('Selecionar Imagem'),
                onPressed: () async {
                  final url = await selecionarEEnviarImagem();

                  if (url != null) {
                    imagemController.text = url;

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Imagem enviada com sucesso'),
                        ),
                      );
                    }
                  }
                },
              ),

              const SizedBox(height: 10),

              TextField(
                controller: imagemController,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Imagem'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('produtos').add({
                'nome': nomeController.text,
                'descricao': descricaoController.text,
                'preco': double.tryParse(precoController.text) ?? 0,
                'imagem': imagemController.text,
                'promocao': false, // 🔥 IMPORTANTE
              });

              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> excluirProduto(String id) async {
    await FirebaseFirestore.instance.collection('produtos').doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Produtos'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        onPressed: () => adicionarProduto(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('produtos').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('Nenhum produto cadastrado'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final produto = docs[index].data() as Map<String, dynamic>;
              final id = docs[index].id;

              final isPromocao = produto['promocao'] == true;

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  leading:
                      (produto['imagem'] != null &&
                          produto['imagem'].toString().isNotEmpty)
                      ? Image.network(
                          produto['imagem'],
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.cake),

                  title: Row(
                    children: [
                      Expanded(child: Text(produto['nome'] ?? '')),

                      if (isPromocao)
                        const Icon(
                          Icons.local_fire_department,
                          color: Colors.orange,
                        ),
                    ],
                  ),

                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(produto['descricao'] ?? ''),
                      Text('R\$ ${produto['preco']}'),
                      if (isPromocao)
                        const Text(
                          "🔥 Promoção da semana",
                          style: TextStyle(color: Colors.orange),
                        ),
                    ],
                  ),

                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.star, color: Colors.orange),
                        onPressed: () => definirPromocao(id),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          editarProduto(context, id, produto);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          excluirProduto(id);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
