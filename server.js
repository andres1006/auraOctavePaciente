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
    const { idStudy } = call.request;
    const diferenciales = [['5','8'],['2','8'],['2','5'],['3','9']];
    const itsDiferencial = [false, false];
    let diferencialToAnalyze = '00';
    let tests=[];
    let identifierStudyCatalog=[];
    const series =  call.request.series;
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
  

    let file = 0;
    tests.forEach(async (testInfo) => {
      file++;
      const { nameSerie, data } = testInfo;
      const dir = `./patientfolder/${nameSerie}_v-2.3.2`;
      console.log("nameSerie = ", nameSerie);
      if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
      }

      const csvWriter = createObjectCsvWriter({
        path: `./patientfolder/${nameSerie}_v-2.3.2/${nameSerie}_v-2.3.2.csv`,
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


    fs.writeFileSync('analyzer.sh', `analyzer('./patientfolder',[${identifierStudyCatalog}])`);

    await exec('octave analyzer.sh');

    const files = fs.readdirSync('./patientfolder');
    const results = files.map((file) => {
      if (file.search('Estudio') != -1) {
        let idResultType;
        const resultFile = fs.readFileSync(`./patientfolder/${file}`, 'utf-8');
        const result = resultFile.split(",").join(" ")
        const typeStudy = file.slice(file.indexOf('_') + 1, file.indexOf('.csv'))
        switch (typeStudy) {
          case 'EA':
            idResultType = 'oct2'
            break;
          case 'EP':
            idResultType = 'oct3'
            break;
          case 'DFT':
            idResultType = 'oct5'
            break;
          case 'DCL':
            idResultType = 'oct8'
            break;
          case 'PKS':
            idResultType = 'oct9'
            break;
          case 'EHM':
            idResultType = 'oct10'
            break;
          case '_diferencial_DFT_vs_DCL':
            idResultType = 'oct58'
            break;
          case '_diferencial_EA_vs_DCL':
            idResultType = 'oct28'
            break;
          case '_diferencial_EA_vs_DFT':
            idResultType = 'oct25'
            break;
          case '_diferencial_EP_vs_PKS':
            idResultType = 'oct39'
            break;
        }
        return { idResultType, result }
      }
    }).filter((element) => element !== undefined
    );

    //fs.rmdirSync('./patientfolder', { recursive: true });

    callback(null, { idStudy, results });

  } catch (error) {
    return callback({
      code: grpc.status.GRPC_STATUS_INTERNAL,
      message: "Ouch!",
    });
  }
};

server.addService(octavePackage.Octave.service, { octave });
server.bind("0.0.0.0:5001", grpc.ServerCredentials.createInsecure());
server.start();
