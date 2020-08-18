const fs = require('fs');
const grpc = require("grpc");
const protoLoader = require("@grpc/proto-loader");

const packageDef = protoLoader.loadSync("octave.proto");
const octavePackage = grpc.loadPackageDefinition(packageDef).octavePackage;
const server = new grpc.Server();

const octave = async (call, callback) => {
  const { tests } = call.request;
  const { studies } = call.request;
  tests.map((testInfo) => {
    const { test } = testInfo;
    const { table } = testInfo.data;
    const dir = `./patientfolder/${test}`;
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
  })

  fs.writeFileSync('analyzer.sh', `analyzer('./patientfolder',[${studies}])`);

  callback(null, { text: "Ready" });
};

server.addService(octavePackage.Octave.service, { octave });
server.bind("0.0.0.0:50051", grpc.ServerCredentials.createInsecure());
server.start();
