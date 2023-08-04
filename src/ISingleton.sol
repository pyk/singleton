// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

interface ISingleton {
  function balanceOf(address token, address account)
    external
    view
    returns (uint256 balance);
  function deposit(address token, address account)
    external
    returns (uint256 amount);
  function transfer(address token, address to, uint256 amount) external;
  function withdraw(address token, address recipient, uint256 amount) external;
}
