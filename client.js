const grpc = require('grpc');
require('dotenv').config();
const protoLoader = require('@grpc/proto-loader');

const { CLASIFICADOR_PARKINSIONISMOS_URL } = process.env;
const packageDef = protoLoader.loadSync('clasificador.proto', {});
const grpcObject = grpc.loadPackageDefinition(packageDef);
const clasificadorPackage = grpcObject.clasificadorPackage;
const text = process.argv[2];

const client = new clasificadorPackage.Clasificador(
  CLASIFICADOR_PARKINSIONISMOS_URL,
  grpc.credentials.createInsecure()
);

client.clasificador(
  {
    text,
  },
  (err, response) => {
    try {
      console.log(`Recieved from server ${JSON.stringify(response)}`);
    } catch (error) {
      console.log(err);
    }
  }
);
