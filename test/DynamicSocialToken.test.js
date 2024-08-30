const { expect } = require("chai");
const { ethers } = require("hardhat");
const { readIntervalsFromFile } = require("../helpers/file-helper");

describe("DynamicSocialToken", function () {
    let DynamicSocialToken, dynamicSocialToken, deployer, addr1;
    let intervals;
    const initialExp = 100;

    beforeEach(async function () {
        DynamicSocialToken = await ethers.getContractFactory("DynamicSocialToken");
        dynamicSocialToken = await DynamicSocialToken.deploy(
            "DynamicSocialToken",
            "DST"
        );
        [deployer, addr1] = await ethers.getSigners();
        intervals = readIntervalsFromFile("dst_interval_config.json");
    });

    it("should have the correct name and symbol", async function () {
        expect(await dynamicSocialToken.name()).to.equal("DynamicSocialToken");
        expect(await dynamicSocialToken.symbol()).to.equal("DST");
    });

    it("should correctly feed off-chain data to a DST token", async function () {
        await dynamicSocialToken.readInterval(intervals);

        await dynamicSocialToken.mint(addr1.address, initialExp);

        let dstData = await dynamicSocialToken.getDstData(1);
        expect(dstData.exp).to.equal(initialExp);

        const feedAmount = 50;
        await dynamicSocialToken.offChainFeed(1, feedAmount);

        dstData = await dynamicSocialToken.getDstData(1);
        expect(dstData.exp).to.equal(initialExp + feedAmount);

        const [level, , url] = await dynamicSocialToken.getDstData(1);
        const { lv: expectedLevel, url: expectedUrl } = intervals.find(
            (interval) =>
                initialExp + feedAmount > interval.left &&
                initialExp + feedAmount <= interval.right
        );
        verifyDstData(dstData, expectedLevel, initialExp + feedAmount, expectedUrl);
    });

    it("should locate right metadata as per json file", async function () {
        //mint
        await dynamicSocialToken.readInterval(intervals);
        await dynamicSocialToken.mint(addr1.address, 0);
        const dstData0 = await dynamicSocialToken.getDstData(1);
        verifyDstData(dstData0, 1, 0, intervals[0].url);

        //offChainFeed
        await dynamicSocialToken.offChainFeed(1, 50);
        const dstData1 = await dynamicSocialToken.getDstData(1);
        verifyDstData(dstData1, 1, 50, intervals[0].url);

        await dynamicSocialToken.offChainFeed(1, 50);
        const dstData2 = await dynamicSocialToken.getDstData(1);
        verifyDstData(dstData2, 2, 100, intervals[1].url);

        await dynamicSocialToken.offChainFeed(1, 115);
        const dstData3 = await dynamicSocialToken.getDstData(1);
        verifyDstData(dstData3, 3, 215, intervals[2].url);

        await dynamicSocialToken.offChainFeed(1, 285);
        const dstData4 = await dynamicSocialToken.getDstData(1);
        verifyDstData(dstData4, 6, 500, intervals[5].url);

        await dynamicSocialToken.offChainFeed(1, 225);
        const dstData5 = await dynamicSocialToken.getDstData(1);
        verifyDstData(dstData5, 6, 725, intervals[5].url);
    });

    it("should revert if intervals are not set", async function () {
        await expect(
            dynamicSocialToken.mint(addr1.address, initialExp)
        ).to.be.revertedWithCustomError(dynamicSocialToken, "IntervalNotSet");
    });

    it("should revert if intervals are empty", async function () {
        await expect(
            dynamicSocialToken.readInterval([])
        ).to.be.revertedWithCustomError(dynamicSocialToken, "EmptyInterval");
    });

    it("should revert if not mint", async function () {
        await dynamicSocialToken.readInterval(intervals);
        await expect(
            dynamicSocialToken.getDstData(1)
        ).to.be.revertedWithCustomError(dynamicSocialToken, "TokenNotMinted");
    });

    it("should lv equal to 1 if mint initial experience is 0", async function () {
        await dynamicSocialToken.readInterval(intervals);
        await dynamicSocialToken.mint(addr1.address, 0);
        const [level, exp, url] = await dynamicSocialToken.getDstData(1);
        expect(level).to.equal(1);
        expect(exp).to.equal(0);
        expect(url).to.equal(intervals[0].url);
    });
});

function verifyDstData(dstData, expectedLevel, expectedExp, expectedUrl) {
    const [level, exp, url] = dstData;
    expect(level).to.equal(expectedLevel);
    expect(exp).to.equal(expectedExp);
    expect(url).to.equal(expectedUrl);
}