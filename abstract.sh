#!/bin/bash

mkdir my-abstract-project && cd my-abstract-project
echo 
npx hardhat init
echo
npm install -D @matterlabs/hardhat-zksync
npm install -D @matterlabs/zksync-contracts
npm install -D zksync-ethers@6 ethers@6
echo
cat << EOF > hardhat.config.ts
import { HardhatUserConfig } from "hardhat/config";
import "@matterlabs/hardhat-zksync";

const config: HardhatUserConfig = {
  zksolc: {
    version: "latest",
    settings: {
      // This is the current name of the "isSystem" flag
      enableEraVMExtensions: false, // Note: NonceHolder and the ContractDeployer system contracts can only be called with a special isSystem flag as true
    },
  },
  defaultNetwork: "abstractTestnet",
  networks: {
    abstractTestnet: {
      url: "https://api.testnet.abs.xyz",
      ethNetwork: "sepolia",
      zksync: true,
      verifyURL:
        "https://api-explorer-verify.testnet.abs.xyz/contract_verification",
    },
  },
  solidity: {
    version: "0.8.24",
  },
};

export default config;

EOF

echo 
mv contracts/Lock.sol contracts/HelloAbstract.sol
cat << EOF > contracts/HelloAbstract.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract HelloAbstract {
    function sayHello() public pure virtual returns (string memory) {
        return "Hello, World!";
    }
}

EOF

echo

npx hardhat compile --network abstractTestnet
npx hardhat vars set DEPLOYER_PRIVATE_KEY
mkdir deploy && touch deploy/deploy.ts
cat << 'EOF_SCRIPT' > deploy/deploy.ts
import { Wallet } from "zksync-ethers";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { Deployer } from "@matterlabs/hardhat-zksync";
import { vars } from "hardhat/config";

// An example of a deploy script that will deploy and call a simple contract.
export default async function (hre: HardhatRuntimeEnvironment) {
  console.log(`Running deploy script`);

  // Initialize the wallet using your private key.
  const wallet = new Wallet(vars.get("DEPLOYER_PRIVATE_KEY"));

  // Create deployer object and load the artifact of the contract we want to deploy.
  const deployer = new Deployer(hre, wallet);
  // Load contract
  const artifact = await deployer.loadArtifact("HelloAbstract");

  // Deploy this contract. The returned object will be of a `Contract` type,
  // similar to the ones in `ethers`.
  const tokenContract = await deployer.deploy(artifact);

  console.log(
    `${
      artifact.contractName
    } was deployed to ${await tokenContract.getAddress()}`
  );
}

EOF_SCRIPT

echo
npx hardhat deploy-zksync --script deploy.ts
echo "Please enter contract address "
read contract
npx hardhat verify --network abstractTestnet $contract
echo 
echo
echo "Thanks for watching and supporting me. Follow me on Twitter https://x.com/NoworkNoresult"
