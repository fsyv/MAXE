import { ethers } from "hardhat";

async function main() {

  console.log("Deploying...")
  const dynamicConsent = await ethers.deployContract("DynamicConsent");
  await dynamicConsent.waitForDeployment();
  console.log("Contract deployed to ${dynamicConsent.target}")
  console.log(
    `Contract deployed to ${dynamicConsent.target}`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
