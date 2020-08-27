const csv = require('csv-parser');
const fs = require('fs');
const grpc = require("grpc");
const protoLoader = require("@grpc/proto-loader");

const packageDef = protoLoader.loadSync("octave.proto");
const octavePackage = grpc.loadPackageDefinition(packageDef).octavePackage;

const client = new octavePackage.Octave(
  "localhost:15000",
  grpc.credentials.createInsecure()
);

const callback = (err, response) => {
  try {
    console.log(`Recieved from server ${JSON.stringify(response)}`);
  } catch (error) {
    console.error(err);
  }
};

const parseCsv = async (file) => {
  const table = []
  const readData = () => new Promise((resolve, reject) => {
    fs.createReadStream(file)
      .pipe(csv())
      .on("data", row => table.push(row))
      .on("error", reject)
      .on("end", async () => {
        resolve();
      });
  });
  await readData();
  return table
};


async function main() {
  const testsTitles = [];
  await fs.readdir('./patienttoread', async (_err, files) => {
    const allPromises = files.map(async (file) => {
      if (file.search('\\.csv') != -1) {
        const test = file.slice(0, file.indexOf('.csv'));
        testsTitles.push(test);
        return parseCsv(`./patienttoread/${file}`);
      }
    });
    const table = await Promise.all(allPromises);

    const tests = testsTitles.map((nameSerie, index) => {
      
      const time = [],
            gazex = [],
            gazey = [],
            stimulux = [],
            stimuluy = [],
            gazevelX = [],
            gazevely = [],
            errorx = [],
            errory = [],
            pupilArea = [],
            gazerawx = [],
            gazerawy = [],
            blinks = [];
      
      for (let i = 0; i < table[index].length; i++) {
        const testData = table[index][i];
        time.push(testData.Time);
        gazex.push(testData.GazeX);
        gazey.push(testData.GazeY);
        stimulux.push(testData.StimulusX);
        stimuluy.push(testData.StimulusY);
        gazevelX.push(testData.GazeVelX);
        gazevely.push(testData.GazeVelY);
        errorx.push(testData.ErrorX);
        errory.push(testData.ErrorY);
        pupilArea.push(testData.PupilArea);
        gazerawx.push(testData.GazeRawX);
        gazerawy.push(testData.GazeRawY);
        blinks.push(testData.Blinks);
      }
        
      const data = { time, gazex, gazey, stimulux, stimuluy, gazevelX, gazevely, errorx, errory, pupilArea, gazerawx, gazerawy, blinks }

      

      const objReturn = { nameSerie, data }
      return objReturn;
    });
    const studies = [2, 5];
    client.octave({ idStudy: "id_mongo", studies, series: [{ identifierStudyCatalog: '3', tests }] }, callback);
  });
}

main();