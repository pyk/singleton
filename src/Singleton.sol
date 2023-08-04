// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import {IERC20} from "oz/interfaces/IERC20.sol";
import {IERC3156FlashBorrower} from "oz/interfaces/IERC3156FlashBorrower.sol";
import {IERC3156FlashLender} from "oz/interfaces/IERC3156FlashLender.sol";
import {Math} from "oz/utils/math/Math.sol";
import {ReentrancyGuard} from "oz/security/ReentrancyGuard.sol";
import {SafeERC20} from "oz/token/ERC20/utils/SafeERC20.sol";

/**
 * @title Singleton
 * @author sepyke.eth
 * @notice Singleton ERC20 vault with ERC3156 compatiblility
 */
contract Singleton is ReentrancyGuard, IERC3156FlashLender {
  using SafeERC20 for IERC20;
  using Math for uint256;

  /// @notice Flash loan fee recipient address
  address public immutable flashLoanFeeRecipient;

  /// @notice Flashloan fee
  /// @dev Fee is in ether units (e.g. 0.0005 ether = 0.05%)
  uint256 public immutable flashLoanFee;

  /// @notice Map account balances
  /// @dev Map: token -> account -> balance
  mapping(address => mapping(address => uint256)) private balances;

  /// @notice Map reserves balances
  /// @dev Map: token -> reserve
  mapping(address => uint256) public reserves;

  /// @dev This event is emitted if flashloan is completed
  event FlashLoan(
    address borrower, address token, uint256 amount, uint256 fee
  );

  /// @dev This error is raised if deposit amount is invalid
  error DepositAmountInvalid();

  /// @dev This error is raised if ETH withdrawal is failed
  error WithdrawFailed();

  /// @dev This error is raised if flashloan token is not supported
  error FlashLoanTokenInvalid();

  /// @dev This error is raised if flashloan amount is greater than balance
  error FlashLoanAmountInvalid();

  /// @dev This error is raised if flashloan failed
  error FlashLoanFailed();

  /// @dev _flashloanFee is in ether units (e.g. 0.0005 ether = 0.05%)
  constructor(address _flashLoanFeeRecipient, uint256 _flashloanFee) {
    flashLoanFeeRecipient = _flashLoanFeeRecipient;
    flashLoanFee = _flashloanFee;
  }

  /**
   * @notice Get token balance of an account
   * @param token The token address. Use address(0) for ETH.
   * @param account The account address
   */
  function balanceOf(address token, address account)
    external
    view
    returns (uint256 balance)
  {
    balance = balances[token][account];
  }

  /**
   * @notice Deposit to the vault
   * @param token The token address
   * @param account The account address
   */
  function deposit(address token, address account)
    external
    nonReentrant
    returns (uint256 amount)
  {
    amount = IERC20(token).balanceOf(address(this)) - reserves[token];
    if (amount == 0) revert DepositAmountInvalid();

    reserves[token] += amount;
    balances[token][account] += amount;
  }

  /**
   * @notice Transfer token balance to an account
   * @dev Revert if amount is greater than account's balance
   * @param token The token address
   * @param to The recipient address
   * @param amount The transfer amount
   */
  function transfer(address token, address to, uint256 amount) external {
    // This will revert if amount > balance
    balances[token][msg.sender] -= amount;
    balances[token][to] += amount;
  }

  /**
   * @notice Withdraw from the vault
   * @dev Revert if amount is greater than account's balance
   * @param token The token address
   * @param recipient The recipient address
   * @param amount The withdrawal amount
   */
  function withdraw(address token, address recipient, uint256 amount)
    external
    nonReentrant
  {
    // This will revert if amount > balance
    balances[token][msg.sender] -= amount;
    reserves[token] -= amount;
    IERC20(token).safeTransfer(recipient, amount);
  }

  /**
   * @notice Get maximum amount of flash loan
   * @param token The token address
   */
  function maxFlashLoan(address token)
    external
    view
    override
    returns (uint256 max)
  {
    max = IERC20(token).balanceOf(address(this));
  }

  /**
   * @notice Get flash loan fee amount
   * @dev Revert if token is not supported
   * @param token The token address
   * @param amount The amount of borrowed token
   */
  function flashFee(address token, uint256 amount)
    external
    view
    override
    returns (uint256 feeAmount)
  {
    if (reserves[token] == 0) revert FlashLoanTokenInvalid();
    feeAmount = flashLoanFee.mulDiv(amount, 1 ether, Math.Rounding.Down);
  }

  /**
   * @notice Execute flash loan
   * @param receiver The flashloan receiver address
   * @param token The token address
   * @param amount The amount of borrowed token
   * @param data Arbitrary data
   */
  function flashLoan(
    IERC3156FlashBorrower receiver,
    address token,
    uint256 amount,
    bytes calldata data
  ) external nonReentrant returns (bool) {
    uint256 balanceBefore = IERC20(token).balanceOf(address(this));
    uint256 feeAmount =
      flashLoanFee.mulDiv(amount, 1 ether, Math.Rounding.Down);

    if (amount > balanceBefore) revert FlashLoanAmountInvalid();
    IERC20(token).safeTransfer(address(receiver), amount);
    bytes32 result =
      receiver.onFlashLoan(msg.sender, token, amount, feeAmount, data);
    if (result != keccak256("ERC3156FlashBorrower.onFlashLoan")) {
      revert FlashLoanFailed();
    }

    uint256 balanceAfter = IERC20(token).balanceOf(address(this));
    if (balanceAfter < balanceBefore) revert FlashLoanFailed();
    uint256 delta = balanceAfter - balanceBefore;
    if (delta < feeAmount) revert FlashLoanFailed();
    IERC20(token).safeTransfer(address(flashLoanFeeRecipient), delta);

    emit FlashLoan(address(receiver), token, amount, delta);

    return true;
  }
}
