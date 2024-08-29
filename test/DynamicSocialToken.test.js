const { expect } = require("chai");
const { ethers } = require("hardhat");
const { readIntervalsFromFile } = require("../helpers/file-helper");

describe("DynamicSocialToken", function () {
    let DynamicSocialToken, dynamicSocialToken, deployer, addr1;
    let intervals;
    let initialExp = 100;

    beforeEach(async function () {
        DynamicSocialToken = await ethers.getContractFactory("DynamicSocialToken");

        dynamicSocialToken = await DynamicSocialToken.deploy("DynamicSocialToken", "DST");

        [deployer, addr1] = await ethers.getSigners();

        intervals = readIntervalsFromFile("dst_interval_config.json");
        await dynamicSocialToken.readInterval(intervals);
    });

    it("should correctly feed off-chain data to a DST token", async function () {
        await dynamicSocialToken.mint(addr1.address, initialExp);

        let dstData = await dynamicSocialToken.getDstData(1);
        expect(dstData.exp).to.equal(initialExp);

        const feedAmount = 50;
        await dynamicSocialToken.offChainFeed(1, feedAmount);

        dstData = await dynamicSocialToken.getDstData(1);
        expect(dstData.exp).to.equal(initialExp + feedAmount);

        const [level, , url] = await dynamicSocialToken.getDstData(1);
        const { lv: expectedLevel, url: expectedUrl } = intervals.find(
            interval => initialExp + feedAmount > interval.left && initialExp + feedAmount <= interval.right
        );
        expect(level).to.equal(expectedLevel);
        expect(url).to.equal(expectedUrl);
    });
});