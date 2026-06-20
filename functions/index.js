const { onCall, HttpsError, onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");
const axios = require("axios");

admin.initializeApp();

const ASAAS_KEY = defineSecret("ASAAS_KEY");

exports.criarPixAsaas = onCall(
  { secrets: [ASAAS_KEY] },
  async (request) => {
    try {
      const { valor, nome, pedidoId } = request.data;

      const apiKey = ASAAS_KEY.value();

      const headers = {
        access_token: apiKey,
        "Content-Type": "application/json",
      };

      const baseURL = "https://www.asaas.com/api/v3";

      // 1. Sempre cria um novo cliente com CPF fixo de teste
      const novoCliente = await axios.post(
        `${baseURL}/customers`,
        {
          name: nome,
          cpfCnpj: "24971563792",
        },
        { headers }
      );

      const customerId = novoCliente.data.id;

      // 2. Cria o pagamento PIX
      const pagamento = await axios.post(
        `${baseURL}/payments`,
        {
          billingType: "PIX",
          value: valor,
          customer: customerId,
          dueDate: new Date(Date.now() + 24 * 60 * 60 * 1000)
            .toISOString()
            .split("T")[0],
          description: `Pedido ${pedidoId}`,
          externalReference: pedidoId,
        },
        { headers }
      );

      const paymentId = pagamento.data.id;

      // 3. Busca o QR Code PIX
      const qrCodeRes = await axios.get(
        `${baseURL}/payments/${paymentId}/pixQrCode`,
        { headers }
      );

      const qrData = qrCodeRes.data;

      return {
        id: paymentId,
        status: pagamento.data.status,
        pixCopiaECola: qrData.payload || null,
        qrCode: qrData.encodedImage
          ? `data:image/png;base64,${qrData.encodedImage}`
          : null,
      };
    } catch (error) {
      console.error(
        "ERRO ASAAS:",
        JSON.stringify(error.response?.data || error.message)
      );

      throw new HttpsError(
        "internal",
        error.response?.data?.errors?.[0]?.description || "Erro ao criar PIX no Asaas"
      );
    }
  }
);

exports.criarCartaoAsaas = onCall(
  { secrets: [ASAAS_KEY] },
  async (request) => {
    try {
      const { valor, nome, cpfCnpj, clienteId, cartao } = request.data;

      const apiKey = ASAAS_KEY.value();

      const headers = {
        access_token: apiKey,
        "Content-Type": "application/json",
      };

      const baseURL = "https://www.asaas.com/api/v3";

      // 1. Cria cliente com CPF real do titular
      const novoCliente = await axios.post(
        `${baseURL}/customers`,
        { name: nome, cpfCnpj },
        { headers }
      );

      const customerId = novoCliente.data.id;

      // 2. Cria cobrança no cartão de crédito
      const pagamento = await axios.post(
        `${baseURL}/payments`,
        {
          billingType: "CREDIT_CARD",
          value: valor,
          customer: customerId,
          dueDate: new Date().toISOString().split("T")[0],
          description: `Pedido ${clienteId}`,
          externalReference: clienteId,
          creditCard: {
            holderName: cartao.nome,
            number: cartao.numero,
            expiryMonth: cartao.mes,
            expiryYear: cartao.ano,
            ccv: cartao.cvv,
          },
          creditCardHolderInfo: {
            name: nome,
            cpfCnpj,
            email: "cliente@email.com",
            phone: "00000000000",
            postalCode: "00000000",
            addressNumber: "0",
          },
        },
        { headers }
      );

      return {
        id: pagamento.data.id,
        status: pagamento.data.status,
      };
    } catch (error) {
      console.error(
        "ERRO CARTAO ASAAS:",
        JSON.stringify(error.response?.data || error.message)
      );

      throw new HttpsError(
        "internal",
        error.response?.data?.errors?.[0]?.description || "Erro ao processar cartão"
      );
    }
  }
);

// Webhook recebe notificações do Asaas e atualiza o Firestore
exports.webhookAsaas = onRequest(async (req, res) => {
  try {
    const evento = req.body;

    console.log("Webhook recebido:", JSON.stringify(evento));

    const pedidoId = evento.payment?.externalReference;
    const status = evento.event;

    if (!pedidoId) {
      res.status(200).send("sem pedidoId");
      return;
    }

    const statusMap = {
      PAYMENT_RECEIVED: "Pago",
      PAYMENT_CONFIRMED: "Pago",
      PAYMENT_OVERDUE: "Vencido",
      PAYMENT_DELETED: "Cancelado",
      PAYMENT_REFUNDED: "Reembolsado",
    };

    const novoStatus = statusMap[status];

    if (!novoStatus) {
      res.status(200).send("evento ignorado");
      return;
    }

    await admin.firestore().collection("pedidos").doc(pedidoId).update({
      statusPagamento: novoStatus,
      statusPedido: novoStatus === "Pago" ? "Confirmado" : "Pendente",
    });

    console.log(`Pedido ${pedidoId} atualizado para ${novoStatus}`);

    res.status(200).send("ok");
  } catch (error) {
    console.error("Erro no webhook:", error);
    res.status(500).send("erro");
  }
});