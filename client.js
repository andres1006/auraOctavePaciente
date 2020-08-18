const grpc = require("grpc");
const protoLoader = require("@grpc/proto-loader");

const packageDef = protoLoader.loadSync("octave.proto");
const octavePackage = grpc.loadPackageDefinition(packageDef).octavePackage;

const client = new octavePackage.Octave(
  "localhost:50051",
  grpc.credentials.createInsecure()
);

const callback = (err, response) => {
  try {
    console.log(`Recieved from server ${JSON.stringify(response)}`);
  } catch (error) {
    console.error(err);
  }
};

const tests = [
  {
    test: "TSVH",
    data: {
      table: [
        { column: [5245.2, 45.124, 234.23, 43.5, 41.45] },
        { column: [2525.3, 5435.4, 2462.2, 42.4, 11.35] },
        { column: [5245.2, 45.124, 234.23, 43.5, 41.34] },
        { column: [2525.3, 5435.4, 2462.2, 42.4, 11.23] },
        { column: [5342.3, 43.674, 264.56, 23.4, 23.65] },
        { column: [5245.2, 45.124, 234.23, 43.5, 41.34] },
        { column: [5245.2, 45.124, 234.23, 43.5, 41.34] },
        { column: [2525.3, 5435.4, 2462.2, 42.4, 11.23] },
        { column: [5245.2, 45.124, 234.23, 43.5, 41.34] },
        { column: [5342.3, 43.674, 264.56, 23.4, 23.65] },
        { column: [2525.3, 5435.4, 2462.2, 42.4, 11.23] },
        { column: [5342.3, 43.674, 264.56, 23.4, 23.65] },
        { column: [5342.3, 43.674, 264.56, 23.4, 23.56] },
      ],
    },
  },
  {
    test: "TASVH",
    data: {
      table: [
        { column: [5245.2, 45.124, 234.23, 43.5, 41.2] },
        { column: [2525.3, 5435.4, 2462.2, 42.4, 11.5] },
        { column: [5342.3, 43.674, 264.56, 23.4, 23.8] },
        { column: [5245.2, 45.124, 234.23, 43.5, 41.34] },
        { column: [2525.3, 5435.4, 2462.2, 42.4, 11.23] },
        { column: [5342.3, 43.674, 264.56, 23.4, 23.65] },
        { column: [5245.2, 45.124, 234.23, 43.5, 41.34] },
        { column: [2525.3, 5435.4, 2462.2, 42.4, 11.23] },
        { column: [5342.3, 43.674, 264.56, 23.4, 23.65] },
        { column: [5245.2, 45.124, 234.23, 43.5, 41.34] },
        { column: [2525.3, 5435.4, 2462.2, 42.4, 11.23] },
        { column: [5342.3, 43.674, 264.56, 23.4, 23.65] },
        { column: [2525.3, 5435.4, 2462.2, 42.4, 11.23] },
      ],
    },
  },
  {
    test: "TSMH",
    data: {
      table: [
        { column: [5245.2, 45.124, 234.23, 43.5, 41.34] },
        { column: [2525.3, 5435.4, 2462.2, 42.4, 11.23] },
        { column: [5342.3, 43.674, 264.56, 23.4, 23.65] },
        { column: [5342.3, 43.674, 264.56, 23.4, 23.65] },
        { column: [5342.3, 43.674, 264.56, 23.4, 23.65] },
        { column: [5342.3, 43.674, 264.56, 23.4, 23.65] },
        { column: [5342.3, 43.674, 264.56, 23.4, 23.65] },
        { column: [5342.3, 43.674, 264.56, 23.4, 23.65] },
        { column: [5342.3, 43.674, 264.56, 23.4, 23.65] },
        { column: [5342.3, 43.674, 264.56, 23.4, 23.65] },
        { column: [5342.3, 43.674, 264.56, 23.4, 23.65] },
        { column: [5342.3, 43.674, 264.56, 23.4, 23.65] },
        { column: [5342.3, 43.674, 264.56, 23.4, 23.65] },
      ],
    },
  },
];

const studies = [2, 5];

client.octave({ tests, studies }, callback);
