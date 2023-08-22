import {
    time,
    loadFixture,
  } from "@nomicfoundation/hardhat-network-helpers";
  import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
  import { expect } from "chai";
  import { ethers } from "hardhat";
  const fs = require("fs");
  // import { DynamicConsent } from "../typechain-types";
  
  describe("DynamicConsent", function () {
    let dynamicConsent;
  

    // queryForResearcher
    it("totallyTest", async function () {
  
      dynamicConsent = await ethers.deployContract("DynamicConsent");
      await dynamicConsent.waitForDeployment();
      console.log(
        `Contract deployed to ${dynamicConsent.target}`
      );
      // 加载数据集
      let datasets0: Array<string> = [
        "./dataset/consents/1/testData.json"
      ];
  
      for (let dataset of datasets0) {
        console.log("Loading dataset: " + dataset);
  
        let training_data = JSON.parse(fs.readFileSync(dataset));
        console.log("Loading dataset competed!");
        // 存储数据
        console.time("insertion");
        for (const i in training_data) {
          console.time("storeRecord: " + dataset + "_" + i);
          await dynamicConsent.storeRecord(
            training_data[i]["patientID"],
            training_data[i]["studyID"],
            training_data[i]["timestamp"],
            training_data[i]["categorySharingChoices"],
            training_data[i]["elementSharingChoices"]
          );
          console.timeEnd("storeRecord: " + dataset + "_" + i);
        }
        console.timeEnd("insertion");
      }
      // let alldata=await dynamicConsent.dataBase;
      // console.log(alldata);
      //////////////////////////////////////////////
      // 加载数据集
      let datasets: Array<string> = [
        "./dataset/queries/testQueryForResearcher.json"
      ];
  
      for (var dataset of datasets) {
        console.log("Load dataset: " + dataset);
  
        let researcher_queries = JSON.parse(fs.readFileSync(dataset))
        for (const i in researcher_queries) {
  
          console.time("queryForResearcher: " + dataset + "_" + i);
  
          let result = await dynamicConsent.queryForResearcher(
            researcher_queries[i]["studyID"],
            researcher_queries[i]["timestamp"],
            researcher_queries[i]["categorySharingChoices"],
            researcher_queries[i]["elementSharingChoices"]
          );
  
          console.timeEnd("queryForResearcher: " + dataset + "_" + i);
  
          console.log("queryForResearcher_" + dataset + "_" + i + ": " + result);
        // 加载数据集
        // queryForPatient
      let datasets1: Array<string> = [
        "./dataset/queries/Testpatient_queries.json"
      ];
  
      for (var dataset of datasets1) {
        console.log("Load dataset: " + dataset);
  
        let researcher_queries = JSON.parse(fs.readFileSync(dataset))
        for (const i in researcher_queries) {
  
          console.time("queryForPatient: " + dataset + "_" + i)
  
          let result = await dynamicConsent.queryForPatient(
            researcher_queries[i]["patientID"],
            researcher_queries[i]["studyID"],
            researcher_queries[i]["startTimestamp"],
            researcher_queries[i]["endTimestamp"]
          )
  
          console.timeEnd("queryForPatient: " + dataset + "_" + i)
  
          console.log("queryForPatient" + dataset + "_" + i + ": " + result);
        }
      }
        }
      }
    })
  
    
  })