// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

contract EthernautMagicNum {
    address public solver;

    function setSolver(address solver_) external {
        solver = solver_;
    }
}

contract MagicNumSolver {
    constructor() {
        bytes memory runtime = hex"602a60005260206000f3";
        assembly {
            return(add(runtime, 0x20), mload(runtime))
        }
    }
}

contract MagicNumAttack {
    function deploy() external returns (address) {
        MagicNumSolver solver = new MagicNumSolver();
        return address(solver);
    }
}

// Local training fixture: the solver runtime is exactly 10 bytes and returns 42.

