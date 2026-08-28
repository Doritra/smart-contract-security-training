// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

contract EthernautFallout {
    mapping(address => uint256) public allocations;
    address payable public owner;

    constructor() payable {
        owner = payable(msg.sender);
    }

    // Typo means this is a normal public function, not a constructor.
    function Fal1out() external payable {
        allocations[msg.sender] += msg.value;
        owner = payable(msg.sender);
    }

    function collectAllocations() external {
        require(msg.sender == owner, "Not owner");
        uint256 amount = allocations[msg.sender];
        allocations[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    function allocatorBalance(address allocator) external view returns (uint256) {
        return allocations[allocator];
    }
}

