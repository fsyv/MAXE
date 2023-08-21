import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
  solidity: "0.8.12",
  mocha: {
    timeout: 10000000000
  },
};

export default config;
