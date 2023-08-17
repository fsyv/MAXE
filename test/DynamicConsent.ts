import {
    time,
    loadFixture,
  } from "@nomicfoundation/hardhat-network-helpers";
  import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
  import { expect } from "chai";
  import { ethers } from "hardhat";
  
  describe("DynamicConsent", function () {
    let dynamicConsent;

    before(async function () {
        // 部署合约
        console.log("Deploying...")
        const dynamicConsent = await ethers.deployContract("DynamicConsent");
        await dynamicConsent.waitForDeployment();
        console.log("Contract deployed to ${dynamicConsent.target}")
        console.log(
          `Contract deployed to ${dynamicConsent.target}`
        );

        // 加载数据集


        console.time("insertion")
        
        // insertPatientID

        console.timeEnd("insertion")
    })

    // queryForResearcher

    // queryForPatient
})