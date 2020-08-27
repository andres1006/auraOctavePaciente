const fs = require('fs');
const grpc = require("grpc");
const protoLoader = require("@grpc/proto-loader");
const { createObjectCsvWriter } = require('csv-writer');
const { exec } = require('child-process-async');

const packageDef = protoLoader.loadSync("octave.proto");
const octavePackage = grpc.loadPackageDefinition(packageDef).octavePackage;
const server = new grpc.Server();

const octave = async (call, callback) => {
  try {
    const { idStudy, idPatient } = call.request;
    const series =  call.request.series;
    const diferenciales = [['5','9'],['2','9'],['2','5'],['3','10']];
    const itsDiferencial = [false, false];
    let diferencialToAnalyze = '00';
    let tests=[];
    let identifierStudyCatalog=[];
    series.forEach(serie => {
      serie.tests.forEach(test =>{
        tests.push(test);
      })
      identifierStudyCatalog.push(serie.identifierStudyCatalog);
    })

    diferenciales.forEach((diferencial, index) => {
      if (diferencialToAnalyze === '00') {
        itsDiferencial[0] = identifierStudyCatalog.includes(diferencial[0]);
        itsDiferencial[1] = identifierStudyCatalog.includes(diferencial[1]);
        diferencialToAnalyze = itsDiferencial[0] && itsDiferencial[1]? `${diferencial[0]}${diferencial[1]}` : '00';
      }
    })

    if (diferencialToAnalyze !== '00') identifierStudyCatalog.push(diferencialToAnalyze);

    tests.forEach(async (testInfo) => {
      const { nameSerie, data } = testInfo;
      const dir = `./${idPatient}/${nameSerie}_v-2.3.2`;
      if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
      }

      const csvWriter = createObjectCsvWriter({
        path: `./${idPatient}/${nameSerie}_v-2.3.2/${nameSerie}_v-2.3.2.csv`,
        header: [
          { id: 'time', title: 'Time(ms)' },
          { id: 'gazex', title: 'GazeX(deg)' },
          { id: 'gazey', title: 'GazeY(deg)' },
          { id: 'stimulux', title: 'StimulusX(deg)' },
          { id: 'stimuluy', title: 'StimulusY(deg)' },
          { id: 'gazevelX', title: 'GazeVelX(deg/s)' },
          { id: 'gazevely', title: 'GazeVelY(deg/s)' },
          { id: 'errorx', title: 'ErrorX(deg)' },
          { id: 'errory', title: 'ErrorY(deg)' },
          { id: 'pupilArea', title: 'PupilArea(px^2)' },
          { id: 'gazeRawx', title: 'GazeRawX(deg)' },
          { id: 'gazeRawy', title: 'GazeRawY(deg)' },
          { id: 'blinks', title: 'Blinks' }
        ]
      });

      const dataToSave = [];
      for (let i = 0; i < data.time.length; i++) {
        const time = data.time[i];
        const gazex = data.gazex[i];
        const gazey = data.gazey[i];
        const stimulux = data.stimulux[i];
        const stimuluy = data.stimuluy[i];
        const gazevelX = data.gazevelX[i];
        const gazevely = data.gazevely[i];
        const errorx = data.errorx[i];
        const errory = data.errory[i];
        const pupilArea = data.pupilArea[i];
        const gazeRawx = data.gazeRawx[i];
        const gazeRawy = data.gazeRawy[i];
        const blinks = data.blinks[i];
        dataToSave.push({ time, gazex, gazey, stimulux, stimuluy, gazevelX, gazevely, errorx, errory, pupilArea, gazeRawx, gazeRawy, blinks });
      }
      await csvWriter.writeRecords(dataToSave);
    });


    fs.writeFileSync('analyzer.sh', `analyzer('./${idPatient}',[${identifierStudyCatalog}])`);

    await exec('octave analyzer.sh');

    const files = fs.readdirSync(`./${idPatient}`);

    let globalResult;

    const results = files.map((file) => {
      if (file.search('Estudio') != -1) {
        let idResultType;
        const resultFile = fs.readFileSync(`./${idPatient}/${file}`, 'utf-8');
        const result = resultFile.split(",").join(" ")
        const typeStudy = file.slice(file.indexOf('_') + 1, file.indexOf('.csv'))
        switch (typeStudy) {
          case 'EA':
          case 'AD':
            idResultType = 'oct2'
            break;
          case 'EP':
          case 'PD':
            idResultType = 'oct3'
            break;
          case 'DFT':
          case 'FD':
          case 'FTD':
            idResultType = 'oct5'
            break;
          case 'DCL':
          case 'MCI':
            idResultType = 'oct9'
            break;
          case 'PKS':
          case 'P':
            idResultType = 'oct10'
            break;
          case 'EHM':
          case 'MHE':
            idResultType = 'oct8'
            break;
          case 'Diferencial_FTD_vs_MCI':
            idResultType = 'oct59'
            break;
          case 'Diferencial_AD_vs_MCI':
            idResultType = 'oct29'
            break;
          case 'Diferencial_AD_vs_FTD':
            idResultType = 'oct25'
            break;
          case 'Diferencial_PD_vs_PKS':
            idResultType = 'oct310'
            break;
        }
        return { idResultType, result }
      }

      if (file.search('GLOBAL') != -1) {
        const globalFile = fs.readFileSync(`./${idPatient}/${file}`, 'utf-8').toString().split("\n");
        globalResultNames = globalFile[0];
        globalResults = globalFile[1];
        globalResult = { globalResultNames, globalResults };
      }

    }).filter((element) => element !== undefined);

    fs.rmdirSync(`./${idPatient}`, { recursive: true });
    callback(null, { idStudy, results, globalResult });

  } catch (error) {
    return callback({
      code: grpc.status.GRPC_STATUS_INTERNAL,
      message: "Ouch!",
    });
  }
};

server.addService(octavePackage.Octave.service, { octave });
server.bind("0.0.0.0:15000", grpc.ServerCredentials.createInsecure());
server.start();
