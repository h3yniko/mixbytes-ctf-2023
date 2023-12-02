// SPDX-License-Identifier: MIT

pragma solidity <0.7.0;

import "../lib/openzeppelin-contracts-3/contracts/utils/Address.sol";
import "../lib/openzeppelin-contracts-3/contracts/proxy/Initializable.sol";
import "forge-std/console.sol";

contract Proxy {
    // bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1)
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    
    struct AddressSlot {
        address value;
    }
    
    constructor(address _logic) public {
        require(Address.isContract(_logic), "e/implementation_not_contract");
        _getAddressSlot(_IMPLEMENTATION_SLOT).value = _logic;

        (bool success,) = _logic.delegatecall(
            abi.encodeWithSignature("initialize()")
        );

        require(success, "e/call_failed");
    }

    function _delegate(address implementation) internal virtual {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    // proxy fallback
    fallback() external payable virtual {
        _delegate(_getAddressSlot(_IMPLEMENTATION_SLOT).value);
    }

    function _getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r_slot := slot
        }
    }
}

contract Executor is Initializable {
    address public owner;

    function initialize() external initializer {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "e/not_owner");
        _;
    }
    
    function execute(address logic) external payable {
        (bool success,) = logic.delegatecall(abi.encodeWithSignature("exec()"));
        require(success, "e/call_fail");
    }
}

// === CUSTOM CODE ===

contract ExecutorTest {
    function exec() external {
        console.log('executed');
    }
}

contract ExecutorEbalka {
    function exec() external {
        console.log('boom!');
        selfdestruct(payable(0x0000000000000000000000000000000000000000));
    }
}