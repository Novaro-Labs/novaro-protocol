import { task } from "hardhat/config";
import { ethers } from "hardhat";
import {readIntervalsFromFile} from "../helpers/file-helper"
import fs from "fs";
import path from "path";


task("deploy-novaro")
  .addParam("mappingName", "The name of the file suffixed with .json to pass to readInterval under config/mapping folder")
  .setAction(async (taskArgs, hre) => {
    //compile contracts
    await hre.run("compile");
    const { ethers, network } = hre;
    //print information
    const [deployer] = await ethers.getSigners();
    console.log("Deploying to network:", network.name);

    //deploy DynamicSocialToken
    const dynamicSocialTokenFactory = await ethers.getContractFactory(
      "DynamicSocialToken",
      deployer
    );
    const dynamicSocialToken = await dynamicSocialTokenFactory.deploy();
    console.log("DynamicSocialToken deployed to:", dynamicSocialToken.target);

    //config NFT metadata
    await dynamicSocialToken.initialize("Dynamic Social Token","DST");

    //read interval for DynamicSocialToken
    await hre.run("read-dst-interval", {
      dstAddress: dynamicSocialToken.target,
      mappingName: taskArgs.mappingName,
    });

    // deploy StakingPool
    const stakingPoolFactory = await ethers.getContractFactory(
      "StakingPool",
      deployer
    );
    const stakingPool = await stakingPoolFactory.deploy();
    console.log("StakingPool deployed to:", stakingPool.target);

    // save contract addresses to file
    const addresses = {
      network: network.name,
      contracts: {
        DynamicSocialToken: dynamicSocialToken.target,
        StakingPool: stakingPool.target,
      },
    };
    // to save contract addresses to file
    const filePath = path.join(
      __dirname,
      `../deployments/${network.name}_addresses.json`
    );
    fs.mkdirSync(path.dirname(filePath), { recursive: true });
    fs.writeFileSync(filePath, JSON.stringify(addresses, null, 2));

    console.log(`Contract addresses saved to ${filePath}`);
  });

task("read-dst-interval", "Configures intervals for DynamicSocialToken")
  .addParam("dstAddress", "The address of the DynamicSocialToken contract")
  .addParam("mappingName", "The name of the mapping to pass to readInterval")
  .setAction(async (taskArgs, hre) => {
    const { dstAddress, mappingName } = taskArgs;

    const [deployer] = await hre.ethers.getSigners();
    console.log("Using deployer account:", deployer.address);

    const DynamicSocialToken = await hre.ethers.getContractFactory(
      "DynamicSocialToken"
    );
    const dynamicSocialToken = DynamicSocialToken.attach(dstAddress);

    try {
      const intervals = readIntervalsFromFile(mappingName);
      console.log("74-intervals\n", intervals);
      await dynamicSocialToken.readInterval(intervals);
    } catch (error) {
      console.error("Error calling readInterval:", error);
    }
    console.log("Interval configuration complete");
  });

// Example usage:
//npx hardhat deploy-novaro --mapping-name dst_interval_config.json --network hardhat

