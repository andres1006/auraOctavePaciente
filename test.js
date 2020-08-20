const csv = require('csv-parser');
const fs = require('fs');

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

async function main(dir) {
  const returnTable = await parseCsv(dir);
  console.log(returnTable);
}

main('./patienttoread/TASVH.csv')