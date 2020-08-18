const fs = require('fs');
const grpc = require("grpc");
const protoLoader = require("@grpc/proto-loader");
const { execSync } = require("child_process");
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
        { id: 'dato01', title: 'Time(ms)' },
        { id: 'dato02', title: 'GazeX(deg)' },
        { id: 'dato03', title: 'GazeY(deg)' },
        { id: 'dato04', title: 'StimulusX(deg)' },
        { id: 'dato05', title: 'StimulusY(deg)' },
        { id: 'dato06', title: 'GazeVelX(deg/s)' },
        { id: 'dato07', title: 'GazeVelY(deg/s)' },
        { id: 'dato08', title: 'ErrorX(deg)' },
        { id: 'dato09', title: 'ErrorY(deg)' },
        { id: 'dato10', title: 'PupilArea(px^2)' },
        { id: 'dato11', title: 'GazeRawX(deg)' },
        { id: 'dato12', title: 'GazeRawY(deg)' },
        { id: 'dato13', title: 'Blinks' }
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

  execSync("octave analyzer.sh");

  callback(null, { text: "Ready" });
};

server.addService(octavePackage.Octave.service, { octave });
server.bind("0.0.0.0:50051", grpc.ServerCredentials.createInsecure());
server.start();
