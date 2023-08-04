// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC20} from "oz/interfaces/IERC20.sol";
import {IERC3156FlashBorrower} from "oz/interfaces/IERC3156FlashBorrower.sol";
import {IERC3156FlashLender} from "oz/interfaces/IERC3156FlashLender.sol";
import {SafeERC20} from "oz/token/ERC20/utils/SafeERC20.sol";

/**
 * @title FlashLoanBorrowerInvalid
 * @author sepyke.eth
 * @notice Contract to test ERC3156 implementation
 */
contract FlashLoanBorrowerInvalid is IERC3156FlashBorrower {
  using SafeERC20 for IERC20;

  IERC3156FlashLender lender;

  constructor(address _lender) {
    lender = IERC3156FlashLender(_lender);
  }

  function execute(address token, uint256 amount) public {
    lender.flashLoan(IERC3156FlashBorrower(address(this)), token, amount, "");
  }

  function onFlashLoan(address, address, uint256, uint256, bytes calldata)
    external
    pure
    returns (bytes32)
  {
    return "";
  }
}

/**
 * @title FlashLoanBorrowerValid
 * @author sepyke.eth
 * @notice Contract to test ERC3156 implementation
 */
contract FlashLoanBorrowerValid is IERC3156FlashBorrower {
  using SafeERC20 for IERC20;

  IERC3156FlashLender lender;
  uint256 repayAmount;

  constructor(address _lender) {
    lender = IERC3156FlashLender(_lender);
  }

  function setRepayAmount(uint256 amount) external {
    repayAmount = amount;
  }

  function execute(address token, uint256 amount) public {
    lender.flashLoan(IERC3156FlashBorrower(address(this)), token, amount, "");
  }

  function onFlashLoan(
    address,
    address token,
    uint256,
    uint256,
    bytes calldata
  ) external override returns (bytes32) {
    IERC20(token).safeTransfer(msg.sender, repayAmount);
    return keccak256("ERC3156FlashBorrower.onFlashLoan");
  }
}
