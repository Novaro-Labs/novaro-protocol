const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NovaroClient", function () {
  let novaroClient, owner, addr1, dst;

  beforeEach(async function () {
    [owner, addr1] = await ethers.getSigners();

    // Deploy the DynamicSocialToken (DST) contract
    const DynamicSocialToken = await ethers.getContractFactory("DynamicSocialToken");
    dst = await DynamicSocialToken.deploy();

    // Deploy the NovaroClient contract with the deployed DST
    const NovaroClient = await ethers.getContractFactory("NovaroClient");
    novaroClient = await NovaroClient.deploy(dst.target);
  });

  it("Should create a FollowerPassToken successfully", async function () {
    const name = "FollowerPass";
    const symbol = "FP";
    const imageUrl = "https://example.com/fp-image";
    const description = "A test follower pass token";

    // Call createFollowerPassToken from owner account
    await expect(
      novaroClient.connect(owner).createFollowerPassToken(name, symbol, imageUrl, description, addr1.address)
    )
      .to.emit(novaroClient, "CreateFollowerPassToken")
      .withArgs(owner.address, addr1.address, symbol, name, imageUrl, description);

    // Check that the token data is stored correctly in the mapping
    const tokenData = await novaroClient.getFollowerPassTokenData(owner.address, addr1.address, symbol);
    expect(tokenData.name).to.equal(name);
    expect(tokenData.symbol).to.equal(symbol);
    expect(tokenData.imageUrl).to.equal(imageUrl);
    expect(tokenData.des).to.equal(description);
    expect(tokenData.deployer).to.equal(owner.address);
    expect(tokenData.boundAccount).to.equal(addr1.address);
  });
});