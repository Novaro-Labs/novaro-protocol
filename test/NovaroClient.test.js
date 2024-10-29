const { expect } = require("chai");
const { ethers } = require("hardhat");
const { readIntervalsFromFile } = require("../helpers/file-helper");
const { INTERVAL_CONFIG_FILE } = require("../helpers/constants");


describe("NovaroClient", function () {
  let novaroClient, owner, addr1, dst;
  let tokenId, salt, initData;
  let registryFactory, accountFactory;
  let preComputedAddress;
  let intervals;
  let pool;
  let initialExp = 0;

  beforeEach(async function () {
    [owner, addr1, pool] = await ethers.getSigners();

    // Deploy the DynamicSocialToken (DST) contract
    const DynamicSocialToken = await ethers.getContractFactory("DynamicSocialToken");
    dst = await DynamicSocialToken.deploy();
    intervals = readIntervalsFromFile(INTERVAL_CONFIG_FILE);
    await dst.readInterval(intervals);
    await dst.mint(addr1.address, initialExp);

    // Deploy the NovaroClient contract with the deployed DST
    const NovaroClient = await ethers.getContractFactory("NovaroClient");
    novaroClient = await NovaroClient.deploy(pool);

    tokenId = 2;
    salt = 1;
    initData = '0x';

    // Deploy Registry contract
    const ERC6551Registry = await ethers.getContractFactory("ERC6551Registry");
    registryFactory = await ERC6551Registry.deploy();

    await novaroClient.setRegistry(registryFactory.target);
    await novaroClient.setDynamicSocialToken(dst.target);

    // Deploy Account contract
    const ERC6551Account = await ethers.getContractFactory("ERC6551Account");
    accountFactory = await ERC6551Account.deploy();
    const chainId = await hre.network.provider.send('eth_chainId');
    console.log("chainId", chainId);
    // Compute the pre-computed address of the account with Create2
    preComputedAddress = await registryFactory.account(accountFactory.target, chainId, dst.target, tokenId, salt);
    // Create an account
    await novaroClient.connect(addr1).createOrFetchAccount(accountFactory.target, chainId, dst.target, tokenId, salt, initData);
    const boundAccount = await novaroClient.getBoundAccount(addr1);
    expect(boundAccount).to.equal(preComputedAddress);
  });


  it("Should create a FollowerPassToken successfully", async function () {
    //address1 creates a follower pass token
    const name = "FollowerPass";
    const symbol = "FP";
    const imageUrl = "https://example.com/fp-image";
    const description = "A test follower pass token";

    // Call createFollowerPassToken from owner account
    await expect(
      novaroClient.connect(addr1).createFollowerPassToken(name, symbol, imageUrl, description)
    )
      .to.emit(novaroClient, "CreateFollowerPassToken")
      .withArgs(addr1.address, preComputedAddress, symbol, name, imageUrl, description);

    const tokens = await novaroClient.getTokenAddresses();
    const token = tokens[0];
    const FollowerPassToken = await hre.ethers.getContractFactory(
      "FollowerPassToken"
    );
    const followerPassToken = FollowerPassToken.attach(token);
    const sellAmount = 10n ** 18n;
    //===================== Sell operation ========================
    //balance before sell
    const sellerBalance = await followerPassToken.balanceOf(addr1);
    const poolBalance = await followerPassToken.balanceOf(pool.address);
    expect(sellerBalance).to.equal(sellAmount);
    expect(poolBalance).to.equal(0);
    //sell operation
    await followerPassToken.connect(addr1).sell(pool, sellAmount);
    //balance after sell
    const sellerBalanceAfter = await followerPassToken.balanceOf(addr1);
    const poolBalanceAfter = await followerPassToken.balanceOf(pool.address);
    expect(sellerBalanceAfter).to.equal(0);
    expect(poolBalanceAfter).to.equal(sellAmount);
    //===================== Buy operation ===================================
    const buyAmount = sellAmount;
    //balance before buy
    const buyerBalance = await followerPassToken.balanceOf(addr1);
    const poolBalanceBeforeBuy = await followerPassToken.balanceOf(pool.address);
    expect(buyerBalance).to.equal(0);
    expect(poolBalanceBeforeBuy).to.equal(buyAmount);
    //approve pool for spending
    await followerPassToken.connect(pool).approve(pool.address, buyAmount);
    //buy operation
//    await followerPassToken.connect(addr1).buy(pool, buyAmount);
    //balance after buy
    const buyerBalanceAfter = await followerPassToken.balanceOf(addr1);
    const poolBalanceAfterBuy = await followerPassToken.balanceOf(pool.address);
    expect(buyerBalanceAfter).to.equal(buyAmount);
    expect(poolBalanceAfterBuy).to.equal(0);
  });
});