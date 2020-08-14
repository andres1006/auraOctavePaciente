const grpc = require("grpc");
const protoLoader = require("@grpc/proto-loader");

const packageDef = protoLoader.loadSync("octave.proto");
const octavePackage = grpc.loadPackageDefinition(packageDef).octavePackage;
const server = new grpc.Server();

const octave = (call, callback) => {
  console.log(call.request);
  callback(null, { text: "Ready" });
};

server.addService(octavePackage.Octave.service, { octave });
server.bind("0.0.0.0:50051", grpc.ServerCredentials.createInsecure());
server.start();
