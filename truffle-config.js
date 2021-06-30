require("ts-node").register({
  files: true,
});

module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "*", // Match any network id
      gas: 4500000,
    },
  },
  mocha: {
    reporter: "eth-gas-reporter",
    // reporterOptions: { onlyCalledMethods: false }, // See options below
  },
  compilers: {
    solc: {
      version: ">=0.7.0 <0.9.0",
      settings: {
        optimizer: {
          enabled: true, // Default: false
          runs: 200, // Default: 200
        },
      },
    },
  },
};
