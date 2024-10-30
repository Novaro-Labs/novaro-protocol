import { task } from "hardhat/config";
import { ethers } from "hardhat";
import { readIntervalsFromFile } from "../helpers/file-helper";
import fs from "fs";
import path from "path";

task("deploy-novaro")
  .addParam(
    "mappingName",
    "The name of the file suffixed with .json to pass to readInterval under config/mapping folder"
  )
  .setAction(async (taskArgs, hre) => {
    //compile contracts
    await hre.run("compile");
    const { ethers, network } = hre;
    //print information
    const [deployer] = await ethers.getSigners();
    console.log("Deploying to network:", network.name);
    console.log("Deployer account:", deployer.address);

    //deploy DynamicSocialToken
    const dynamicSocialTokenFactory = await ethers.getContractFactory(
      "DynamicSocialToken",
      deployer
    );
    const dynamicSocialToken = await dynamicSocialTokenFactory.deploy();
    console.log("DynamicSocialToken deployed to:", dynamicSocialToken.target);

    //Deploy Account Contract
    const AccountFactory = await ethers.getContractFactory(
      "ERC6551Account",
      deployer
    );
    const accountFactory = await AccountFactory.deploy();
    console.log("AccountFactory deployed to:", accountFactory.target);

    //Deploy Registry
    const AccountRegistry = await ethers.getContractFactory(
      "ERC6551Registry",
      deployer
    );
    const accountRegistry = await AccountRegistry.deploy();
    console.log("AccountRegistry deployed to:", accountRegistry.target);

    //read interval for DynamicSocialToken
    await hre.run("read-dst-interval", {
      dstAddress: dynamicSocialToken.target,
      mappingName: taskArgs.mappingName,
    });

     //deploy liquidity pool
     const LiquidityPool = await ethers.getContractFactory(
     "PoolMocker",
          deployer
     );
     const liquidityPool = await LiquidityPool.deploy();

    // deploy NovaroClient
    const NovaroClient = await ethers.getContractFactory(
      "NovaroClient",
      deployer
    );
    console.log("LiquidityPool deployed to:", liquidityPool.target)
    const novaroClient = await NovaroClient.deploy(liquidityPool.target);
    console.log("NovaroClient deployed to:", novaroClient.target);

    // set feeder address for DynamicSocialToken
    await dynamicSocialToken.setFeeder(novaroClient.target);
    console.log("Feeder address set for DynamicSocialToken");

    //set dst address for client
    await novaroClient.setDynamicSocialToken(dynamicSocialToken.target);

    //set registry address for client
    await novaroClient.setRegistry(accountRegistry.target)

    // save contract addresses to file
    const addresses = {
      network: network.name,
      feeder: novaroClient.target,
      env: process.env.ENV,
      contracts: {
        LiquidityPool: liquidityPool.target,
        DynamicSocialToken: dynamicSocialToken.target,
        NovaroClient: novaroClient.target,
        AccountFactory: accountFactory.target,
        AccountRegistry: accountRegistry.target,
      },
    };
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
      await dynamicSocialToken.readInterval(intervals);
    } catch (error) {
      console.error("Error calling readInterval:", error);
    }
    console.log("Interval configuration complete");
  });

// Example usage:
//npx hardhat deploy-novaro --mapping-name dst_interval_config.json --network hardhat
