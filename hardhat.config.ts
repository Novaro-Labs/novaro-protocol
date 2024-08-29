import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import glob from "glob";
import path from "path";

glob.sync("./tasks/**/*.ts").forEach(function (file) {
  require(path.resolve(file));
});

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: "0.8.24",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],
  },
  networks: {
    hardhat: {
      chainId: 1337,
    },
    localhost: {
      url: "http://127.0.0.1:8545",
      chainId: 1337,
    },
  },
  gasReporter: {
    enabled: false,
  },
  typechain: {
    outDir: "./target/typechain-types",
  },
};

export default config;
