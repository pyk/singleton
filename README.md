# Singleton

Singleton ERC20 vault contract with flash loan support.

## Features

- ✅ Compatible with any ERC20
- ✅ Reduce gas fees on ERC20 transfer via internal transfer
- ✅ Support ERC3156 (Flash Loan) with custom fees & recipient

## Get started

Install and use directly on your project:

```sh
forge install pyk/singleton
```

Example usage:

```sol
import {Singleton} from "singleton/Singleton.sol";

contract MyVault is Singleton {
  constructor(adddress owner, uint256 fees) Singleton(owner, fees) {
    //
  }
}
```

Or deploy directly using the factory:

- Ethereum (_To be deployed_)
- Arbitrum (_To be deployed_)
- Optimism (_To be deployed_)
- Base (_To be deployed_)

## Tests

Run test using the following command:

```sh
forge test --fork-url ETH_RPC_URL
```

```
[⠢] Compiling...
No files changed, compilation skipped

Running 12 tests for test/Singleton.t.sol:SingletonTest
[PASS] testDeposit() (gas: 219034)
[PASS] testDepositWithCustomAccount() (gas: 220687)
[PASS] testDepositWithZeroAmount() (gas: 162848)
[PASS] testFlashLoanFee() (gas: 220030)
[PASS] testFlashLoanMax() (gas: 217064)
[PASS] testFlashLoanWithBorrowerNotRepaid() (gas: 689035)
[PASS] testFlashLoanWithInvalidBorrower() (gas: 383503)
[PASS] testFlashLoanWithValidBorrower() (gas: 714253)
[PASS] testTransfer() (gas: 239685)
[PASS] testWithdraw() (gas: 241137)
[PASS] testWithdrawWithAmountGreaterThanBalance() (gas: 220333)
[PASS] testWithdrawWithCustomRecipient() (gas: 245264)
Test result: ok. 12 passed; 0 failed; 0 skipped; finished in 3.38s
Ran 1 test suites: 12 tests passed, 0 failed, 0 skipped (12 total tests)
```
