require("dotenv").config();
const grpc = require("grpc");
const protoLoader = require("@grpc/proto-loader");
const starProcess = require("./runProcess");

const { CLASIFICADOR_PARKINSIONISMOS_URL } = process.env;
const packageDef = protoLoader.loadSync("octave.proto", {});
const grpcObject = grpc.loadPackageDefinition(packageDef);
const octavePackage = grpcObject.octavePackage;
const server = new grpc.Server();

// singlenton de intancia de funcion para proceso de consola
let runProcess = null;

server.bind(
  CLASIFICADOR_PARKINSIONISMOS_URL,
  grpc.ServerCredentials.createInsecure()
);
server.addService(octavePackage.Clasificador.service, { octave });
server.start();
function octave(call, callback) {
  if (!runProcess) {
    runProcess = starProcess();
  }
  runProcess().then((out) => {
    callback(null, { text: out.data, code: out.code });
  });
}
