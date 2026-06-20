const functions = require("firebase-functions");
const {MercadoPagoConfig, Payment} = require("mercadopago");

exports.criarPix = functions.https.onCall(async (request) => {
  try {
    console.log("================================");
    console.log("REQUEST RECEBIDO:");
    console.log(request);
    console.log("================================");

    const valor = Number(request.data.valor);

    const descricao =
      request.data.descricao || "Pedido Doces da Rita";

    console.log("VALOR:", valor);
    console.log("DESCRICAO:", descricao);

    if (isNaN(valor) || valor <= 0) {
      throw new Error("Valor inválido: " + valor);
    }

    const accessToken = [
      "APP_USR-1213397638394314",
      "-060610-d1bd2cd7af4c9d4",
      "f81d74f79efad768a-3452806195",
    ].join("");

    const client = new MercadoPagoConfig({
      accessToken,
    });

    const payment = new Payment(client);

    const resultado = await payment.create({
      body: {
        transaction_amount: valor,
        description: descricao,
        payment_method_id: "pix",
        payer: {
          email: "cliente@docesdarita.com",
        },
      },
    });

    console.log("PIX CRIADO COM SUCESSO");
    console.log("ID:", resultado.id);

    return {
      sucesso: true,
      id: resultado.id,
      status: resultado.status,
      qrCode:
        resultado.point_of_interaction.transaction_data.qr_code,
      qrCodeBase64:
        resultado.point_of_interaction.transaction_data.qr_code_base64,
      ticketUrl:
        resultado.point_of_interaction.transaction_data.ticket_url,
    };
  } catch (error) {
    console.error("ERRO PIX:");
    console.error(error);

    return {
      sucesso: false,
      erro: error.message,
    };
  }
});
