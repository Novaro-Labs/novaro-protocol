const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("ERC6551 Account", async function () {

  let owner, registry, account, dynamicSocialToken;
  let tokenId, salt, initData;

  beforeEach(async function () {
    [owner] = await ethers.getSigners();
    tokenId = 1;
    salt = 1;
    initData = '0x';

    // Deploy Registry contract
    const ERC6551Registry = await ethers.getContractFactory("ERC6551Registry");
    registryFactory = await ERC6551Registry.deploy();

    // Deploy Account contract
    const ERC6551Account = await ethers.getContractFactory("ERC6551Account");
    accountFactory = await ERC6551Account.deploy();

    // Deploy DST but don't read interval data
    DynamicSocialToken = await ethers.getContractFactory("DynamicSocialToken");
    dynamicSocialToken = await DynamicSocialToken.deploy();
  });

  it("Deploy Mock ERC20 and transfer to ERC6551 Account", async function () {
    // Deploy Mock ERC20
    const ERC20Mocker = await ethers.getContractFactory("ERC20Mocker", owner);
    const erc20Mocker = await ERC20Mocker.deploy();
    //Create ERC6551 Account
    const chainId = await hre.network.provider.send('eth_chainId');
    console.log("chainId", chainId);
    const account = await registryFactory.createAccount(accountFactory.target, chainId, dynamicSocialToken.target, tokenId, salt, initData);
    const preComputedAddress = await registryFactory.account(accountFactory.target, chainId, dynamicSocialToken.target, tokenId, salt);
    console.log("preComputedAddress", preComputedAddress);
    //Transfer ERC20 to ERC6551 Account
    const balance_before = await erc20Mocker.balanceOf(preComputedAddress);
    console.log("balance_before", balance_before);
    const amount = 1000n;
    await erc20Mocker.transfer(preComputedAddress, amount);
    const balance_after = await erc20Mocker.balanceOf(preComputedAddress);
    console.log("balance_after", balance_after);
    expect(balance_after).to.equal(balance_before + amount);
  });

  it("Deploy Mock ERC721 and transfer to ERC6551 Account", async function () {
    // Deploy Mock ERC721
    const ERC721Mocker = await ethers.getContractFactory("ERC721Mocker", owner);
    const erc721Mocker = await ERC721Mocker.deploy();
    //Create ERC6551 Account
    const chainId = await hre.network.provider.send('eth_chainId');
    console.log("chainId", chainId);
    const account = await registryFactory.createAccount(accountFactory.target, chainId, dynamicSocialToken.target, tokenId, salt, initData);
    const preComputedAddress = await registryFactory.account(accountFactory.target, chainId, dynamicSocialToken.target, tokenId, salt);
    console.log("owner", owner.address)
    console.log("preComputedAddress", preComputedAddress);
    //Transfer ERC721 to ERC6551 Account
    const balance_before = await erc721Mocker.balanceOf(preComputedAddress);
    const owner_before = await erc721Mocker.ownerOf(tokenId);
    console.log("owner_before", owner_before);
    console.log("balance_before", balance_before);
    await erc721Mocker.transferFrom(owner.address, preComputedAddress, tokenId);
    const balance_after = await erc721Mocker.balanceOf(preComputedAddress);
    const owner_after = await erc721Mocker.ownerOf(tokenId);
    console.log("owner_after", owner_after);
    console.log("balance_after", balance_after);
    expect(balance_after).to.equal(balance_before + 1n);
  });

  it("Trigger Client create follower pass token and transfer to ERC6551 Account", async function () {
    // Deploy the DynamicSocialToken (DST) contract
    const DynamicSocialToken = await ethers.getContractFactory("DynamicSocialToken");
    dst = await DynamicSocialToken.deploy();
    // Deploy the NovaroClient contract with the deployed DST
    const NovaroClient = await ethers.getContractFactory("NovaroClient");
    novaroClient = await NovaroClient.deploy(dst.target);
    //create ERC6551 Account
    const chainId = await hre.network.provider.send('eth_chainId');
    console.log("chainId", chainId);
    const account = await registryFactory.createAccount(accountFactory.target, chainId, dynamicSocialToken.target, tokenId, salt, initData);
    const preComputedAddress = await registryFactory.account(accountFactory.target, chainId, dynamicSocialToken.target, tokenId, salt);
    console.log("owner", owner.address)
    // Create Follower Token
    const name = "FollowerPass";
    const symbol = "FP";
    const imageUrl = "https://example.com/fp-image";
    const description = "A test follower pass token";
    await novaroClient.createFollowerPassToken(name, symbol, imageUrl, description, preComputedAddress);
    //get tokendata
    const tokenData = await novaroClient.getAllFollowerPassToken();
    expect(tokenData.length).to.equal(1);
    if (tokenData.length = 0) { return; }
    //get token address
    const tokenAddresses = await novaroClient.getTokenAddresses();
    console.log("tokenAddress", tokenAddresses[0]);
    const token = await ethers.getContractAt("ERC20", tokenAddresses[0]);
    const balance_of_owner = await token.balanceOf(owner.address);
    console.log("balance_of_owner", balance_of_owner);
    expect(balance_of_owner).to.equal(0n);

    const balanceOf_account = await token.balanceOf(preComputedAddress);
    console.log("balanceOf_account", balanceOf_account);
    expect(balanceOf_account).to.equal(10n ** 18n);

    //metadata
    expect(tokenData[0].deployer).to.equal(owner.address);
    expect(tokenData[0].boundAccount).to.equal(preComputedAddress);
    expect(tokenData[0].token).to.equal(tokenAddresses[0]);
    expect(tokenData[0].name).to.equal(name);
    expect(tokenData[0].symbol).to.equal(symbol);
    expect(tokenData[0].imageUrl).to.equal(imageUrl);
    expect(tokenData[0].des).to.equal(description);

  })
});