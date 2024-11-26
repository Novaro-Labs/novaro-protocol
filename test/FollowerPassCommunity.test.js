const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("FollowerPassCommunity Tests", function () {
    let deployer, admin, user, treasury, boundAccount;
    let usdt, followerPassCommunity, followerPassToken;

    beforeEach(async function () {
        [deployer, admin, user, treasury, boundAccount] = await ethers.getSigners();

        const USDT = await ethers.getContractFactory("ERC20Mocker");
        usdt = await USDT.deploy();

        await usdt.mint(user.address, ethers.parseUnits("1", 16));

        const FollowerPassCommunity = await ethers.getContractFactory("FollowerPassCommunity", admin);
        followerPassCommunity = await FollowerPassCommunity.deploy(
            usdt.target,
            "FollowerPass Community Share",
            "FPCS",
            treasury.address,
            boundAccount.address
        );

        await followerPassCommunity.connect(admin).setConfig(
            ethers.parseUnits("1", 16),
            60
        );
    });

    it("Should allow a user to join the community", async function () {
        const fee = await followerPassCommunity.getFee();

        await usdt.connect(user).approve(followerPassCommunity.target, fee);

        await followerPassCommunity.connect(user).join();

        expect(await followerPassCommunity.isMemberOf(user.address)).to.be.true;

        const memberCount = await followerPassCommunity.getMemberCount();
        expect(memberCount).to.equal(1);
    });

    it("Should allow deposit and mint share tokens", async function () {
        const depositAmount = ethers.parseUnits("1", 16);

        await usdt.connect(user).approve(followerPassCommunity.target, depositAmount);

        await followerPassCommunity.connect(user).deposit(depositAmount, user.address);

        const shareBalance = await followerPassCommunity.balanceOf(user.address);
        expect(shareBalance).to.equal(depositAmount);
        console.log("User Share Token Balance:", ethers.formatUnits(shareBalance, 18), 'ether');
    });

    it("Should create a follower pass token", async function () {
        await followerPassCommunity.connect(admin).createFollowerPassToken(
            "Follower Pass",
            "FP",
            "SourceID123",
            "A description for Follower Pass"
        );

        const followerPassTokenAddress = await followerPassCommunity.getFollowerPassToken();
        followerPassToken = await ethers.getContractAt("FollowerPassToken", followerPassTokenAddress);

        expect(await followerPassToken.name()).to.equal("Follower Pass");
        expect(await followerPassToken.symbol()).to.equal("FP");
        expect(await followerPassToken.balanceOf(boundAccount)).to.equal(ethers.parseUnits("1", 18));
    });

    it("Should allow share token to be swapped for follower pass tokens", async function () {
        const depositAmount = ethers.parseUnits("1", 16);
        await usdt.connect(user).approve(followerPassCommunity.target, depositAmount);
        await followerPassCommunity.connect(user).deposit(depositAmount, user.address);
        //share balance after deposit
        const shareBalance = await followerPassCommunity.balanceOf(user.address);
        console.log("User Share Token Balance:", ethers.formatUnits(shareBalance, 18), 'ether');
        //create follower pass token after deposit
        await followerPassCommunity.connect(admin).createFollowerPassToken(
            "Follower Pass",
            "FP",
            "SourceID123",
            "A description for Follower Pass"
        );
        const followerPassTokenAddress = await followerPassCommunity.getFollowerPassToken();
        followerPassToken = await ethers.getContractAt("FollowerPassToken", followerPassTokenAddress);
        //swap share token for follower pass token


        await followerPassToken.connect(boundAccount).approve(followerPassCommunity.target, 100);
        await followerPassCommunity.connect(user).swap(100);

        const userBalance = await followerPassToken.balanceOf(user.address);
        expect(userBalance).to.equal(shareBalance * 60n / 100n);
    });
});