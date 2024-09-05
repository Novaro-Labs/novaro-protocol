const { expect } = require("chai");
const { ethers } = require("hardhat");
const { readIntervalsFromFile } = require("../helpers/file-helper");
const { INTERVAL_CONFIG_FILE } = require("../helpers/constants");


describe("Delegation Mint for DST", function () {
  let NovaroClient;
  let novaroClient;
  let DynamicSocialToken;
  let dynamicSocialToken;
  let deployer;
  let user;
  let novaId = "Nova_client_delegation_mint_837241";

  beforeEach(async function () {
    [deployer, user] = await ethers.getSigners();

    DynamicSocialToken = await ethers.getContractFactory("DynamicSocialToken");
    dynamicSocialToken = await DynamicSocialToken.deploy("DynamicSocialToken", "DST");
    const intervals = readIntervalsFromFile(INTERVAL_CONFIG_FILE);
    await dynamicSocialToken.readInterval(intervals);

    NovaroClient = await ethers.getContractFactory("NovaroClient");
    novaroClient = await NovaroClient.deploy(dynamicSocialToken.target);
  });

  describe("onDelegateReceived", function () {
    it("Should mint a DST for the NovaID and store token ID", async function () {
      await novaroClient.onDelegateReceived(novaId);

      const tokenId = await novaroClient.getDelegateTokenId(novaId);
      expect(tokenId).to.be.equal(2);

      //client owner the token
      const balanceOfClient = await dynamicSocialToken.balanceOf(novaroClient.target);
      expect(balanceOfClient).to.be.equal(1);

      //user don't owner ant DST
      const balanceOfUser = await dynamicSocialToken.balanceOf(user.address);
      expect(balanceOfUser).to.be.equal(0);
    });
  });

  describe("createTokenBoundAccount", function () {
    it("Should create a token-bound account and transfer DST to user", async function () {
      await novaroClient.onDelegateReceived(novaId);

      const tokenId = await novaroClient.getDelegateTokenId(novaId);
      expect(tokenId).to.be.equal(2);
      expect(await dynamicSocialToken.balanceOf(novaroClient.target)).to.equal(1);

      await expect(novaroClient.createTokenBoundAccount(user.address, novaId))
        .to.emit(novaroClient, "CreateTokenBoundAccount")
        .withArgs(user.address, tokenId, novaId);

      expect(await dynamicSocialToken.ownerOf(tokenId)).to.equal(user.address);

      expect(await dynamicSocialToken.balanceOf(novaroClient.target)).to.equal(0);


    });
  });

  describe("exceptions", function () {
    it("Should revert if DST is already bound", async function () {
      await novaroClient.onDelegateReceived(novaId);
      await expect(
        novaroClient.onDelegateReceived(novaId)
      ).to.be.revertedWithCustomError(novaroClient, "AlreadyBoundDST");
    });

    it("Should revert if DST is mint and transfer and mint again", async function () {

      await novaroClient.onDelegateReceived(novaId);

      const tokenId = await novaroClient.getDelegateTokenId(novaId);
      expect(tokenId).to.be.equal(2);
      expect(await dynamicSocialToken.balanceOf(novaroClient.target)).to.equal(1);

      await expect(novaroClient.createTokenBoundAccount(user.address, novaId))
        .to.emit(novaroClient, "CreateTokenBoundAccount")
        .withArgs(user.address, tokenId, novaId);

      expect(await dynamicSocialToken.ownerOf(tokenId)).to.equal(user.address);

      expect(await dynamicSocialToken.balanceOf(novaroClient.target)).to.equal(0);
      await expect(
        novaroClient.onDelegateReceived(novaId)
      ).to.be.revertedWithCustomError(novaroClient, "AlreadyBoundDST");
    });

    it("Should revert if transfer before mint DST", async function () {
      await expect(
        novaroClient.createTokenBoundAccount(user.address, novaId)
      ).to.be.revertedWithCustomError(novaroClient, "DSTNotMinted");
    });
  });
});
