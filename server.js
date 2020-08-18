const fs = require('fs');
const grpc = require("grpc");
const protoLoader = require("@grpc/proto-loader");
const createCsvWriter = require('csv-writer').createObjectCsvWriter;

const packageDef = protoLoader.loadSync("octave.proto");
const octavePackage = grpc.loadPackageDefinition(packageDef).octavePackage;
const server = new grpc.Server();

const octave = async (call, callback) => {
  const { tests } = call.request;
  const { studies } = call.request;

  tests.forEach(async (testInfo) => {
    const { test } = testInfo;
    const { table } = testInfo.data;

    const dir = `./patientfolder/${test}`;

    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }

    const csvWriter = createCsvWriter({
      path: `./patientfolder/${test}/${test}.csv`,
      header: [
        { id: 'dato01', title: 'DATO01' },
        { id: 'dato02', title: 'DATO02' },
        { id: 'dato03', title: 'DATO03' },
        { id: 'dato04', title: 'DATO04' },
        { id: 'dato05', title: 'DATO05' },
        { id: 'dato06', title: 'DATO06' },
        { id: 'dato07', title: 'DATO07' },
        { id: 'dato08', title: 'DATO08' },
        { id: 'dato09', title: 'DATO09' },
        { id: 'dato10', title: 'DATO10' },
        { id: 'dato11', title: 'DATO11' },
        { id: 'dato12', title: 'DATO12' },
        { id: 'dato13', title: 'DATO13' }
      ]
    });

    const firstColumn = table[0].column;

    const records = firstColumn.map((element, index) => {
      const objReturn = {
        dato01: element,
        dato02: table[1].column[index],
        dato03: table[2].column[index],
        dato04: table[3].column[index],
        dato05: table[4].column[index],
        dato06: table[5].column[index],
        dato07: table[6].column[index],
        dato08: table[7].column[index],
        dato09: table[8].column[index],
        dato10: table[0].column[index],
        dato11: table[10].column[index],
        dato12: table[11].column[index],
        dato13: table[12].column[index],
      };
      return objReturn;
    });

    await csvWriter.writeRecords(records);

  });

  fs.writeFileSync('analyzer.sh', `analyzer('./patientfolder',[${studies}])`);

  callback(null, { text: "Ready" });
};

server.addService(octavePackage.Octave.service, { octave });
server.bind("0.0.0.0:50051", grpc.ServerCredentials.createInsecure());
server.start();
