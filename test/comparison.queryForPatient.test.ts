import {
    time,
    loadFixture,
} from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";
import { DynamicConsent } from "../typechain-types";
const fs = require("fs");
import { storeRecord, queryForResearcher, queryForPatient } from "../scripts/DynamicConsent"

describe("DynamicConsent", function () {
    let dynamicConsent: DynamicConsent;

    before(async function () {
        // 部署合约
        console.log("Deploying...");
        dynamicConsent = await ethers.deployContract("DynamicConsent");
        await dynamicConsent.waitForDeployment();
        console.log(
            `Contract deployed to ${dynamicConsent.target}`
        );

        // 加载数据集
        // let datasets: Array<string> = [
        //     "./dataset/consents/1/training_data.json",
        //     "./dataset/consents/2/training_data.json",
        //     "./dataset/consents/3/training_data.json",
        //     "./dataset/consents/4/training_data.json"
        // ];

        let datasets: Array<string> = [
            "./dataset/consents/1/training_data.json"
        ];


        for (let dataset of datasets) {

            console.log("Loading dataset: " + dataset);

            let training_data = JSON.parse(fs.readFileSync(dataset));
            // 存储数据
            console.log("Runing storeRecord function...");

            let counter = 0;
            for (const i in training_data) {

                // if (counter > 50) break;
                counter = counter + 1;

                await dynamicConsent.storeRecord(
                    training_data[i]["patientID"],
                    training_data[i]["studyID"],
                    training_data[i]["timestamp"],
                    training_data[i]["categorySharingChoices"],
                    training_data[i]["elementSharingChoices"]
                );

                // 测试脚本
                storeRecord(
                    training_data[i]["patientID"],
                    training_data[i]["studyID"],
                    training_data[i]["timestamp"],
                    training_data[i]["categorySharingChoices"],
                    training_data[i]["elementSharingChoices"]
                );
            }

            console.log(dataset + "_total: " + training_data.length);
        }
    })

    // queryForPatient
    it("queryForPatient", async function () {

        // 加载数据集
        let datasets: Array<string> = [
            "./dataset/queries/patient_queries.json"
        ];

        for (var dataset of datasets) {
            console.log("Load dataset: " + dataset);

            let researcher_queries = JSON.parse(fs.readFileSync(dataset))
            for (const i in researcher_queries) {

                let result = await dynamicConsent.queryForPatient(
                    researcher_queries[i]["patientID"],
                    researcher_queries[i]["studyID"],
                    researcher_queries[i]["startTimestamp"],
                    researcher_queries[i]["endTimestamp"]
                )

                let result_ts = queryForPatient(
                    researcher_queries[i]["patientID"],
                    researcher_queries[i]["studyID"],
                    researcher_queries[i]["startTimestamp"],
                    researcher_queries[i]["endTimestamp"]
                );

                if (result.length != result_ts.length || result != result_ts) {
                    console.error("Input: " +
                        researcher_queries[i]["patientID"] + ", " +
                        researcher_queries[i]["studyID"] + ", " +
                        researcher_queries[i]["startTimestamp"] + ", " +
                        researcher_queries[i]["endTimestamp"] + " %c failing", "color: green;"
                    )


                    console.error("queryForResearcher_" + dataset + "_" + i + " solidity: " + result);
                    console.error("queryForResearcher_" + dataset + "_" + i + " hardhat : " + result_ts);

                    let content = "Input: " +
                        researcher_queries[i]["patientID"] + ", " +
                        researcher_queries[i]["studyID"] + ", " +
                        researcher_queries[i]["startTimestamp"] + ", " +
                        researcher_queries[i]["endTimestamp"] + "\n\n" +
                        " solidity: " + result + "\n\n" +
                        " hardhat : " + result_ts;

                    fs.writeFile("./test/comparison.output.txt", content, (err) => {
                        if (err) {
                            console.error('Error writing to file:', err);
                        } else {
                            console.log('Content successfully written to file.');
                        }
                    });

                    return;
                }

                console.log("Input: " +
                    researcher_queries[i]["patientID"] + ", " +
                    researcher_queries[i]["studyID"] + ", " +
                    researcher_queries[i]["startTimestamp"] + ", " +
                    researcher_queries[i]["endTimestamp"] + " %c passing", "color: green;"
                )
            }
        }
    })

})