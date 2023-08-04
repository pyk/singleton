// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Singleton} from "./Singleton.sol";

/**
 * @title SingletonFactory
 * @author sepyke.eth
 * @notice Factory contract to deploy new Singleton ERC20 vault
 */
contract SingletonFactory {
  /// @dev This event is emitted if singleton is deployed
  event SingletonDeployed(address);

  /**
   * @notice Deploy new Singleton
   * @dev Fee is in ether units, for example 0.0005*10^18 is 0.05%
   * @param _flashLoanFeeRecipient The flash loan fee recipient address
   * @param _flashLoanFee The flash loan fee in ether units
   */
  function deploy(address _flashLoanFeeRecipient, uint256 _flashLoanFee)
    external
    returns (address singleton)
  {
    bytes memory params =
      abi.encode(msg.sender, _flashLoanFeeRecipient, _flashLoanFee);
    bytes32 salt = keccak256(params);
    singleton =
      address(new Singleton{salt: salt}(_flashLoanFeeRecipient, _flashLoanFee));
    emit SingletonDeployed(singleton);
  }
}
