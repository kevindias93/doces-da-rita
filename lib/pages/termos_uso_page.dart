import 'package:flutter/material.dart';

class TermosPage extends StatelessWidget {
  const TermosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Termos de Uso',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.description_outlined,
                      color: Colors.white70,
                      size: 32,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Termos de Uso',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Doces da Rita · Última atualização: Junho de 2026',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Seções dos termos
              _TermoSection(
                numero: '1',
                titulo: 'Objetivo',
                conteudo:
                    'O aplicativo Doces da Rita tem como finalidade permitir a visualização de produtos, realização de pedidos, acompanhamento de entregas e comunicação com a confeitaria.',
              ),
              _TermoSection(
                numero: '2',
                titulo: 'Cadastro',
                conteudo:
                    'O usuário é responsável por fornecer informações verdadeiras e atualizadas, incluindo nome, telefone e endereço de entrega.',
              ),
              _TermoSection(
                numero: '3',
                titulo: 'Pedidos',
                conteudo:
                    'Os pedidos realizados através do aplicativo estão sujeitos à disponibilidade dos produtos.\n\nA Doces da Rita poderá cancelar pedidos em situações excepcionais, como indisponibilidade de estoque, falhas técnicas ou suspeita de fraude.',
              ),
              _TermoSection(
                numero: '4',
                titulo: 'Preços',
                conteudo:
                    'Os preços exibidos no aplicativo podem ser alterados sem aviso prévio.\n\nO valor válido será aquele apresentado no momento da confirmação do pedido.',
              ),
              _TermoSection(
                numero: '5',
                titulo: 'Responsabilidades',
                conteudo:
                    'O usuário compromete-se a utilizar o aplicativo de forma adequada e respeitosa.\n\nTentativas de fraude, uso indevido de cupons ou manipulação do sistema poderão resultar no bloqueio da conta.',
              ),
              _TermoSection(
                numero: '6',
                titulo: 'Alterações',
                conteudo:
                    'Estes termos poderão ser atualizados periodicamente sem aviso prévio.',
              ),
              _TermoSection(
                numero: '7',
                titulo: 'Contato',
                conteudo:
                    'Em caso de dúvidas, entre em contato com a Doces da Rita através dos canais oficiais de atendimento.',
                isLast: true,
              ),

              const SizedBox(height: 8),

              // Rodapé
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.deepPurple.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.deepPurple,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Ao utilizar o aplicativo, você concorda com estes termos.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.deepPurple.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _TermoSection extends StatelessWidget {
  final String numero;
  final String titulo;
  final String conteudo;
  final bool isLast;

  const _TermoSection({
    required this.numero,
    required this.titulo,
    required this.conteudo,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 16 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Número da seção
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.deepPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                numero,
                style: const TextStyle(
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Conteúdo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    conteudo,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      height: 1.55,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
