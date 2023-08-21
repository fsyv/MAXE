import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
  defaultNetwork: "hardhat",
  solidity: {
    version: "0.8.12",
    // Optional
    settings:
    {
      // Optional: Optimizer settings
      "optimizer": {
        // Disabled by default.
        // NOTE: enabled=false still leaves some optimizations on. See comments below.
        // WARNING: Before version 0.8.6 omitting the 'enabled' key was not equivalent to setting
        // it to false and would actually disable all the optimizations.
        "enabled": true,
      },
      // Version of the EVM to compile for.
      // Affects type checking and code generation. Can be homestead,
      // tangerineWhistle, spuriousDragon, byzantium, constantinople, petersburg, istanbul or berlin
      "evmVersion": "byzantium",
    }
  },
  networks: {
    hardhat: {
      blockGasLimit: 0xfffffff,
      gasPrice: 1,
      initialBaseFeePerGas: 1,
      gas: 0xffffff,
    }
  },
  gasReporter: {
    enabled: true,
  }
};

export default config;