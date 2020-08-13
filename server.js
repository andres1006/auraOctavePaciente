require("dotenv").config();
const grpc = require("grpc");
const protoLoader = require("@grpc/proto-loader");
const starProcess = require("./runProcess");

const packageDef = protoLoader.loadSync("octave.proto", {});
const grpcObject = grpc.loadPackageDefinition(packageDef);
const octavePackage = grpcObject.octavePackage;
const server = new grpc.Server();

// singlenton de intancia de funcion para proceso de consola
let runProcess = null;

function octave(call, callback) {
  if (!runProcess) {
    runProcess = starProcess();
  }
  runProcess().then((out) => {
    callback(null, { text: out.data });
  });
}

server.addService(octavePackage.Octacve.service, { octave });
server.bind("0.0.0.0:50051", grpc.ServerCredentials.createInsecure());
server.start();
