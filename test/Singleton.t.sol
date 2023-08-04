// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC20} from "oz/interfaces/IERC20.sol";
import {Test} from "forge-std/Test.sol";

import {Singleton} from "src/Singleton.sol";
import {
  FlashLoanBorrowerInvalid,
  FlashLoanBorrowerValid
} from "./FlashLoanBorrower.sol";

contract SingletonTest is Test {
  Singleton public vault;

  address alice = vm.addr(0xA11CE);
  address bob = vm.addr(0xB0B);
  address flashLoanFeeRecipient = vm.addr(0xB45ED);
  address weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

  function setUp() public {
    vault = new Singleton(flashLoanFeeRecipient, 0.0005 ether);
  }

  // ==========================================================================
  // == Deposit ===============================================================
  // ==========================================================================

  /// @dev Make sure balances and reserves are updated
  function testDeposit() public {
    // Pre-condition check
    uint256 balance = vault.balanceOf(weth, alice);
    assertEq(balance, 0);

    uint256 depositAmount = 1 ether;
    deal(weth, alice, depositAmount);

    // alice deposits for their own account
    vm.startPrank(alice);
    IERC20(weth).transfer(address(vault), depositAmount);
    vault.deposit(weth, alice);
    vm.stopPrank();

    // alice vault's balance for should be updated
    balance = vault.balanceOf(weth, alice);
    assertEq(balance, depositAmount);

    // Reserve should be updated
    uint256 reserve = vault.reserves(weth);
    assertEq(reserve, depositAmount);
  }

  /// @dev Make sure account balances and vault's reserves are updated
  function testDepositWithCustomAccount() public {
    // Pre-condition check
    uint256 balance = vault.balanceOf(weth, bob);
    assertEq(balance, 0);

    uint256 depositAmount = 1 ether;
    deal(weth, alice, depositAmount);

    // alice deposits for bob
    vm.startPrank(alice);
    IERC20(weth).transfer(address(vault), depositAmount);
    vault.deposit(weth, bob); // bob as account
    vm.stopPrank();

    // bob vault's balance for should be updated
    balance = vault.balanceOf(weth, bob);
    assertEq(balance, depositAmount);

    // Reserve should be updated
    uint256 reserve = vault.reserves(weth);
    assertEq(reserve, depositAmount);
  }

  /// @dev Make sure it revert when deposit 0 ETH
  function testDepositWithZeroAmount() public {
    deal(weth, alice, 1 ether);

    vm.startPrank(alice);
    vm.expectRevert(
      abi.encodeWithSelector(Singleton.DepositAmountInvalid.selector)
    );
    vault.deposit(weth, alice);
    vm.stopPrank();
  }

  // ==========================================================================
  // == Transfer ==============================================================
  // ==========================================================================

  /// @dev Make sure balances are updated and reserves is not changed
  function testTransfer() public {
    uint256 depositAmount = 1 ether;
    uint256 transferAmount = 1 ether;

    deal(weth, alice, depositAmount);

    // alice deposits for their own account
    vm.startPrank(alice);
    IERC20(weth).transfer(address(vault), depositAmount);
    vault.deposit(weth, alice);
    vm.stopPrank();

    // alice transfer to bob
    vm.startPrank(alice);
    vault.transfer(weth, bob, transferAmount);
    vm.stopPrank();

    // alice balance should be updated
    assertEq(vault.balanceOf(weth, alice), 0);
    assertEq(vault.balanceOf(weth, bob), transferAmount);
  }

  // ==========================================================================
  // == Withdraw ==============================================================
  // ==========================================================================

  /// @dev Make sure balances and reserves are updated
  function testWithdraw() public {
    uint256 depositAmount = 1 ether;
    uint256 withdrawAmount = 1 ether;

    deal(weth, alice, depositAmount);

    // alice deposits for their own account
    vm.startPrank(alice);
    IERC20(weth).transfer(address(vault), depositAmount);
    vault.deposit(weth, alice);
    vm.stopPrank();

    // alice withdraw to their own account
    vm.startPrank(alice);
    vault.withdraw(weth, alice, withdrawAmount);
    vm.stopPrank();

    // alice balance should be updated
    assertEq(IERC20(weth).balanceOf(alice), withdrawAmount);
  }

  /// @dev Make sure balances and reserves are updated
  function testWithdrawWithCustomRecipient() public {
    uint256 depositAmount = 1 ether;
    uint256 withdrawAmount = 1 ether;

    deal(weth, alice, depositAmount);

    // alice deposits for their own account
    vm.startPrank(alice);
    IERC20(weth).transfer(address(vault), depositAmount);
    vault.deposit(weth, alice);
    vm.stopPrank();

    // alice withdraw to bob
    vm.startPrank(alice);
    vault.withdraw(weth, bob, withdrawAmount);
    vm.stopPrank();

    // alice and bob balance should be updated
    assertEq(IERC20(weth).balanceOf(alice), 0);
    assertEq(IERC20(weth).balanceOf(bob), withdrawAmount);
  }

  /// @dev Make sure balances and reserves are updated
  function testWithdrawWithAmountGreaterThanBalance() public {
    uint256 depositAmount = 1 ether;
    uint256 withdrawAmount = 3 ether;

    deal(weth, alice, depositAmount);

    // alice deposits for their own account
    vm.startPrank(alice);
    IERC20(weth).transfer(address(vault), depositAmount);
    vault.deposit(weth, alice);
    vm.stopPrank();

    // alice withdraw should be failed
    vm.startPrank(alice);
    vm.expectRevert();
    vault.withdraw(weth, alice, withdrawAmount);
    vm.stopPrank();
  }

  // ==========================================================================
  // == Flashloan =============================================================
  // ==========================================================================

  /// @dev Make sure max flash loan returns correct amount
  function testFlashLoanMax() public {
    uint256 depositAmount = 1 ether;
    deal(weth, alice, depositAmount);
    vm.startPrank(alice);
    IERC20(weth).transfer(address(vault), depositAmount);
    vault.deposit(weth, alice);
    vm.stopPrank();

    uint256 max = vault.maxFlashLoan(weth);
    assertEq(max, depositAmount);
  }

  /// @dev Make sure flashFee is compatible with ERC3156
  function testFlashLoanFee() public {
    uint256 depositAmount = 1 ether;
    deal(weth, alice, depositAmount);
    vm.startPrank(alice);
    IERC20(weth).transfer(address(vault), depositAmount);
    vault.deposit(weth, alice);
    vm.stopPrank();

    uint256 feeAmount = vault.flashFee(weth, 1 ether);
    assertEq(feeAmount, 0.0005 ether);

    vm.expectRevert(
      abi.encodeWithSelector(Singleton.FlashLoanTokenInvalid.selector)
    );
    vault.flashFee(address(0), 1 ether);
  }

  /// @dev Make sure flash loan reverted if borrower is not valid ERC3156
  function testFlashLoanWithInvalidBorrower() public {
    uint256 depositAmount = 1 ether;
    deal(weth, alice, depositAmount);
    vm.startPrank(alice);
    IERC20(weth).transfer(address(vault), depositAmount);
    vault.deposit(weth, alice);
    vm.stopPrank();

    FlashLoanBorrowerInvalid borrower =
      new FlashLoanBorrowerInvalid(address(vault));

    vm.expectRevert(abi.encodeWithSelector(Singleton.FlashLoanFailed.selector));
    borrower.execute(weth, depositAmount);
  }

  /// @dev Make sure flash loan reverted if borrower not repaid
  function testFlashLoanWithBorrowerNotRepaid() public {
    uint256 depositAmount = 1 ether;
    deal(weth, alice, depositAmount);
    vm.startPrank(alice);
    IERC20(weth).transfer(address(vault), depositAmount);
    vault.deposit(weth, alice);
    vm.stopPrank();

    FlashLoanBorrowerValid borrower =
      new FlashLoanBorrowerValid(address(vault));
    borrower.setRepayAmount(0.5 ether);
    deal(weth, address(borrower), depositAmount);

    vm.expectRevert(abi.encodeWithSelector(Singleton.FlashLoanFailed.selector));
    borrower.execute(weth, depositAmount);
  }

  /// @dev Make sure flash load is succesfull
  function testFlashLoanWithValidBorrower() public {
    uint256 depositAmount = 1 ether;
    deal(weth, alice, depositAmount);
    vm.startPrank(alice);
    IERC20(weth).transfer(address(vault), depositAmount);
    vault.deposit(weth, alice);
    vm.stopPrank();

    FlashLoanBorrowerValid borrower =
      new FlashLoanBorrowerValid(address(vault));
    borrower.setRepayAmount(depositAmount + 0.1 ether);
    deal(weth, address(borrower), depositAmount + 0.1 ether);

    borrower.execute(weth, depositAmount);

    // Make sure fee recipient balance increased
    assertEq(IERC20(weth).balanceOf(flashLoanFeeRecipient), 0.1 ether);
  }
}
