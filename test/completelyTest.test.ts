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
                "./dataset/consents/1/training_data.json",
              //  "./dataset/consents/2/training_data.json",
              //   "./dataset/consents/3/training_data.json",
              //   "./dataset/consents/4/training_data.json"
            ];
            for (let dataset of datasets0) {
                console.log("Loading dataset: " + dataset);
    
                let training_data = JSON.parse(fs.readFileSync(dataset));
                // 存储数据
                console.log("Runing storeRecord function...");
                let startTime: number = Date.now();
    
                for (const i in training_data) {
                    await dynamicConsent.storeRecord(
                        training_data[i]["patientID"],
                        training_data[i]["studyID"],
                        training_data[i]["timestamp"],
                        training_data[i]["categorySharingChoices"],
                        training_data[i]["elementSharingChoices"]
                    );
                }
                let endTime: number = Date.now();
                let consumeTime = endTime - startTime;
    
                console.log(dataset + "_total: " + training_data.length + ", consume time: " + consumeTime + "ms, average time: " + consumeTime / training_data.length + "ms.");
            }
      // let alldata=await dynamicConsent.dataBase;
      // console.log(alldata);
      //////////////////////////////////////////////
      // 加载数据集
      let datasets: Array<string> = [
        "./dataset/queries/researcher_queries.json"
      ];
  
      for (var dataset of datasets) {
        console.log("Load dataset: " + dataset);
  
        let researcher_queries = JSON.parse(fs.readFileSync(dataset))
        let startTime: number = Date.now();
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
          
        }
        let endTime: number = Date.now();
        let consumeTime = endTime - startTime;

        console.log(dataset + "_total: " + researcher_queries.length + ", consume time: " + consumeTime + "ms, average time: " + consumeTime / researcher_queries.length + "ms.");
      }
        // 加载数据集
        // queryForPatient
      let datasets1: Array<string> = [
        "./dataset/queries/patient_queries.json"
      ];
  
      for (var dataset of datasets1) {
        console.log("Load dataset: " + dataset);
        let startTime: number = Date.now();
        let researcher_queries2 = JSON.parse(fs.readFileSync(dataset))
        for (const i in researcher_queries2) {
  
          console.time("queryForPatient: " + dataset + "_" + i)
  
          let result = await dynamicConsent.queryForPatient(
            researcher_queries2[i]["patientID"],
            researcher_queries2[i]["studyID"],
            researcher_queries2[i]["startTimestamp"],
            researcher_queries2[i]["endTimestamp"]
          )
  
          console.timeEnd("queryForPatient: " + dataset + "_" + i)
  
          console.log("queryForPatient" + dataset + "_" + i + ": " + result);
        }
        let endTime2: number = Date.now();
        let consumeTime2 = endTime2 - startTime;
  
        console.log(dataset + "_total: " + researcher_queries2.length + ", consume time: " + consumeTime2 + "ms, average time: " + consumeTime2 / researcher_queries2.length + "ms.");
      }

      
    })
  
    
  })