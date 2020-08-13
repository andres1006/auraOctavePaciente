require('dotenv').config();
const grpc = require('grpc');
const protoLoader = require('@grpc/proto-loader');
const starProcess = require('./runProcess');

const { CLASIFICADOR_PARKINSIONISMOS_URL } = process.env;
const packageDef = protoLoader.loadSync('clasificador.proto', {});
const grpcObject = grpc.loadPackageDefinition(packageDef);
const clasificadorPackage = grpcObject.clasificadorPackage;
const server = new grpc.Server();

// singlenton de intancia de funcion para proceso de consola
let runProcess = null;

server.bind(CLASIFICADOR_PARKINSIONISMOS_URL, grpc.ServerCredentials.createInsecure());
server.addService(clasificadorPackage.Clasificador.service, {
  'clasificador': clasificador,
});
server.start();
function clasificador(call, callback) {
  if (!runProcess) {
    runProcess = starProcess();
  }
  runProcess(`cd ../Clasificador_Parkinsionismos_vs_control/src && ./main ${call.request.text}`).then((out) => {
    callback(null, { text: out.data, code: out.code });
  });
}
