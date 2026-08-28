# Smart Contract Security Training

[![Forge Tests](https://github.com/Doritra/smart-contract-security-training/actions/workflows/test.yml/badge.svg)](https://github.com/Doritra/smart-contract-security-training/actions/workflows/test.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Solidity](https://img.shields.io/badge/Solidity-0.8.28-blue)](https://soliditylang.org/)
[![Foundry](https://img.shields.io/badge/Built%20with-Foundry-000000.svg)](https://getfoundry.sh)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

Hands-on smart contract security training with **runnable Foundry PoCs** — not just theory.

## What's inside

| Track | Coverage | Status |
|---|---|---|
| **Ethernaut (classic)** | All 31 levels — solution + exploit tests | ✅ 31/31 |
| **Ethernaut 2025** | 9 new levels — signatures, EIP-7702, reentrancy | ✅ 7/9 (2 WIP) |
| **Damn Vulnerable DeFi** | 10 exploits — reentrancy, oracle, access control | ✅ done |
| **Reports** | HackenProof/Immunefi-style write-ups | ✅ 4 examples + template |

Every exploit is a **Foundry test you can run** — see exactly how the attack works, then read the report for the fix.

## Highlights (Ethernaut 2025)

- **Impersonator / Forger** — ECDSA signature malleability bypasses used-signature guards
- **EllipticToken** — spoofable permit hash drains a signer's balance
- **UniqueNFT** — EIP-7702 turns an EOA-only mint into a reentrancy hole
- **BetHouse** — deposit + lock flow to register as bettor
- **MagicAnimalCarousel** — crate owner overwrite

## Quick start

```bash
git clone https://github.com/Doritra/smart-contract-security-training.git
cd smart-contract-security-training
forge build
forge test          # runs every exploit + control test
```

Requirements: [Foundry](https://getfoundry.sh) (forge).

## Layout

```
src/ethernaut/        # Ethernaut classic level contracts
src/ethernaut2025/    # Ethernaut 2025 fixtures (local models of the originals)
test/ethernaut/       # exploit + control tests (classic)
test/ethernaut2025/   # exploit + control tests (2025)
```

## Reports

HackenProof/Immunefi-style write-ups for the exploits (severity, root cause, PoC, impact, fix):

- [`reports/`](reports/) — template + 4 example reports

## Notes

- The 2025 fixtures are **local models** of the originals (same vulnerability, same exploit surface) — the originals require OpenZeppelin 4.6-era dependencies not vendored on modern Foundry.
- Withdrawal of Forger mints 200 ether; cashback uses EIP-7702 delegation (`0xef0100` prefix) — see the tests.
- Some Damn Vulnerable DeFi tests require a mainnet fork (`MAINNET_FORKING_URL`) or external state — the CI badge covers the self-contained Ethernaut + Ethernaut 2025 suites. Run those locally with `forge test --match-path "test/<challenge>/*"`.

## License

MIT
