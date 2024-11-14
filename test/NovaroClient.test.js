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
  let poolMocker;
  let initialExp = 0;

  beforeEach(async function () {
    [owner, addr1] = await ethers.getSigners();

    // Deploy the DynamicSocialToken (DST) contract
    const DynamicSocialToken = await ethers.getContractFactory("DynamicSocialToken");
    dst = await DynamicSocialToken.deploy();
    intervals = readIntervalsFromFile(INTERVAL_CONFIG_FILE);
    await dst.readInterval(intervals);
    await dst.mint(addr1.address, initialExp);

    //deploy the pool mocker
    const PoolMocker = await ethers.getContractFactory("PoolMocker");
    poolMocker = await PoolMocker.deploy();

    // Deploy the NovaroClient contract with the deployed DST
    const NovaroClient = await ethers.getContractFactory("NovaroClient");
    novaroClient = await NovaroClient.deploy(poolMocker.target);

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
    const sourceId = "15323";
    const description = "A test follower pass token";

    // Call createFollowerPassToken from owner account
    await expect(
      novaroClient.connect(addr1).createFollowerPassToken(name, symbol, sourceId, description)
    )
      .to.emit(novaroClient, "CreateFollowerPassToken")
      .withArgs(addr1.address, preComputedAddress, symbol, name, sourceId, description);

    const tokens = await novaroClient.getTokenAddresses();
    const token = tokens[0];
    const FollowerPassToken = await hre.ethers.getContractFactory(
      "FollowerPassToken"
    );

    const followerPassToken = FollowerPassToken.attach(token);
    const sellAmount = 10n ** 18n;
    //===================== Sell operation ========================
    //balance before sell
    const sellerBalance = await followerPassToken.balanceOf(preComputedAddress);
    const poolBalance = await followerPassToken.balanceOf(poolMocker.target);
    expect(sellerBalance).to.equal(sellAmount);
    expect(poolBalance).to.equal(0);

    //approve pool for spending
    await followerPassToken.connect(addr1).approve(preComputedAddress, sellAmount);
    await followerPassToken.connect(addr1).approve(addr1.address, sellAmount);
    await followerPassToken.connect(addr1).approve(poolMocker.target, sellAmount);

    //sell operation
    await followerPassToken.connect(addr1).sell(poolMocker.target, sellAmount);

    //balance after sell
    const sellerBalanceAfter = await followerPassToken.balanceOf(addr1);
    const poolBalanceAfter = await followerPassToken.balanceOf(poolMocker.target);
    expect(sellerBalanceAfter).to.equal(0);
    expect(poolBalanceAfter).to.equal(sellAmount);
    //===================== Buy operation ===================================
    const ethValue = ethers.parseUnits("1", "ether");
    const amountToBuy = ethers.parseUnits("100", 18);
    const initialPoolBalance = await ethers.provider.getBalance(poolMocker.target);
    await followerPassToken.connect(addr1).buy(poolMocker.target, amountToBuy, { value: ethValue });
    const finalPoolBalance = await ethers.provider.getBalance(poolMocker.target);
    expect(finalPoolBalance).to.equal(ethValue);
  });
});