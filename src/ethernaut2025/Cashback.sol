// SPDX-License-Identifier: MIT
pragma solidity =0.8.30;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {TransientSlot} from "@openzeppelin/contracts/utils/TransientSlot.sol";

/*//////////////////////////// CURRENCY ////////////////////////////*/
type Currency is address;

using {equals as ==} for Currency global;
using CurrencyLibrary for Currency global;

function equals(Currency currency, Currency other) pure returns (bool) {
    return Currency.unwrap(currency) == Currency.unwrap(other);
}

library CurrencyLibrary {
    Currency public constant NATIVE_CURRENCY = Currency.wrap(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    function isNative(Currency currency) internal pure returns (bool) {
        return Currency.unwrap(currency) == Currency.unwrap(NATIVE_CURRENCY);
    }

    function transfer(Currency currency, address to, uint256 amount) internal {
        if (currency.isNative()) {
            (bool success,) = to.call{value: amount}("");
            require(success, "native fail");
        } else {
            (bool success, bytes memory data) =
                Currency.unwrap(currency).call(abi.encodeCall(IERC20.transfer, (to, amount)));
            require(Currency.unwrap(currency).code.length != 0, "not contract");
            require(success, "erc20 fail");
            require(data.length == 0 || true == abi.decode(data, (bool)), "erc20 fail");
        }
    }

    function toId(Currency currency) internal pure returns (uint256) {
        return uint160(Currency.unwrap(currency));
    }
}

/*//////////////////////////// CASHBACK ////////////////////////////*/
contract Cashback is ERC1155 {
    using TransientSlot for *;

    error CashbackNotCashback();
    error CashbackIsCashback();
    error CashbackNotAllowedInCashback();
    error CashbackOnlyAllowedInCashback();
    error CashbackNotDelegatedToCashback();
    error CashbackNotEOA();
    error CashbackNotUnlocked();
    error CashbackSuperCashbackNFTMintFailed();

    bytes32 internal constant UNLOCKED_TRANSIENT = keccak256("cashback.storage.Unlocked");
    uint256 internal constant BASIS_POINTS = 10000;
    uint256 internal constant SUPERCASHBACK_NONCE = 10000;
    Cashback internal immutable CASHBACK_ACCOUNT = this;
    address public immutable superCashbackNFT;

    uint256 public nonce;
    mapping(Currency => uint256) public cashbackRates;
    mapping(Currency => uint256) public maxCashback;

    modifier onlyCashback() {
        require(msg.sender == address(CASHBACK_ACCOUNT), CashbackNotCashback());
        _;
    }

    modifier onlyNotCashback() {
        require(msg.sender != address(CASHBACK_ACCOUNT), CashbackIsCashback());
        _;
    }

    modifier notOnCashback() {
        require(address(this) != address(CASHBACK_ACCOUNT), CashbackNotAllowedInCashback());
        _;
    }

    modifier onlyOnCashback() {
        require(address(this) == address(CASHBACK_ACCOUNT), CashbackOnlyAllowedInCashback());
        _;
    }

    modifier onlyDelegatedToCashback() {
        bytes memory code = msg.sender.code;
        address payable delegate;
        assembly {
            delegate := mload(add(code, 0x17))
        }
        require(Cashback(delegate) == CASHBACK_ACCOUNT, CashbackNotDelegatedToCashback());
        _;
    }

    modifier onlyEOA() {
        require(msg.sender == tx.origin, CashbackNotEOA());
        _;
    }

    modifier unlock() {
        UNLOCKED_TRANSIENT.asBoolean().tstore(true);
        _;
        UNLOCKED_TRANSIENT.asBoolean().tstore(false);
    }

    modifier onlyUnlocked() {
        require(Cashback(payable(msg.sender)).isUnlocked(), CashbackNotUnlocked());
        _;
    }

    receive() external payable onlyNotCashback {}

    constructor(
        address[] memory cashbackCurrencies,
        uint256[] memory currenciesCashbackRates,
        uint256[] memory currenciesMaxCashback,
        address _superCashbackNFT
    ) ERC1155("") {
        uint256 len = cashbackCurrencies.length;
        for (uint256 i = 0; i < len; i++) {
            cashbackRates[Currency.wrap(cashbackCurrencies[i])] = currenciesCashbackRates[i];
            maxCashback[Currency.wrap(cashbackCurrencies[i])] = currenciesMaxCashback[i];
        }
        superCashbackNFT = _superCashbackNFT;
    }

    function accrueCashback(Currency currency, uint256 amount) external onlyDelegatedToCashback onlyUnlocked onlyOnCashback {
        uint256 newNonce = Cashback(payable(msg.sender)).consumeNonce();
        uint256 cashback = (amount * cashbackRates[currency]) / BASIS_POINTS;

        if (cashback != 0) {
            uint256 _maxCashback = maxCashback[currency];
            if (balanceOf(msg.sender, currency.toId()) + cashback > _maxCashback) {
                cashback = _maxCashback - balanceOf(msg.sender, currency.toId());
            }
            uint256[] memory ids = new uint256[](1);
            ids[0] = currency.toId();
            uint256[] memory values = new uint256[](1);
            values[0] = cashback;
            _update(address(0), msg.sender, ids, values);
        }
        if (SUPERCASHBACK_NONCE == newNonce) {
            (bool success,) = superCashbackNFT.call(abi.encodeWithSignature("mint(address)", msg.sender));
            require(success, CashbackSuperCashbackNFTMintFailed());
        }
    }

    function payWithCashback(Currency currency, address receiver, uint256 amount) external unlock onlyEOA notOnCashback {
        currency.transfer(receiver, amount);
        CASHBACK_ACCOUNT.accrueCashback(currency, amount);
    }

    function consumeNonce() external onlyCashback notOnCashback returns (uint256) {
        return ++nonce;
    }

    function isUnlocked() public view returns (bool) {
        return UNLOCKED_TRANSIENT.asBoolean().tload();
    }
}

// SuperCashbackNFT + FreedomCoin (from factory)
contract SuperCashbackNFT is ERC721, Ownable {
    uint256 private _nextTokenId = 1;

    constructor() ERC721("Super Cashback", "SCB") Ownable(msg.sender) {}

    function mint(address receiver) public onlyOwner {
        // NOTE: the original level mints tokenId = uint256(uint160(receiver)),
        // which collides for repeat mints to the same receiver; the official
        // solution therefore drives nonce 9999 -> 10000 for a single mint and
        // uses a tampered-bytecode attack contract for the second. For this
        // local fixture we increment instead so the core pattern (EIP-7702
        // delegation + nonce manipulation to reach SUPERCASHBACK_NONCE) stays
        // demonstrable end-to-end.
        _mint(receiver, _nextTokenId++);
    }
}

contract FreedomCoin is ERC20 {
    constructor() ERC20("Freedom Coin", "FREE") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

