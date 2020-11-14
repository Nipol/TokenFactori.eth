import { task } from 'hardhat/config';
import '@nomiclabs/hardhat-waffle';
import '@nomiclabs/hardhat-ethers';
import '@nomiclabs/hardhat-solhint';
import 'hardhat-gas-reporter';

task('accounts', 'Prints the list of accounts', async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(await account.getAddress());
  }
});

export default {
  defaultNetwork: 'hardhat',
  networks: {
    hardhat: {
      gas: 9000000,
      blockGasLimit: 12000000,
    },
    coverage: {
      url: 'http://localhost:8555',
    },
    // rinkeby: {
    //   url: `https://${process.env.RIVET_KEY}.rinkeby.rpc.rivet.cloud/`,
    //   accounts: [`${process.env.DEPOLYER_PK}`],
    //   gasPrice: 8000000000,
    //   timeout: 500000
    // }
  },
  solidity: {
    version: '0.6.12',
    settings: {
      optimizer: {
        enabled: true,
        runs: 999999,
      },
    },
  },
  paths: {
    sources: './contracts',
    tests: './test',
    cache: './cache',
    artifacts: './artifacts',
  },
  gasReporter: {
    currency: 'USD',
    gasPrice: 1,
  },
};
