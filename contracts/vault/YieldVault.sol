// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract YieldVault {
    address public immutable asset;
    mapping(address => uint256) public shares;
    uint256 public totalShares;

    event Deposited(address indexed account, uint256 assets, uint256 sharesMinted);

    constructor(address asset_) {
        asset = asset_;
    }

    function recordDeposit(address account, uint256 assets) external returns (uint256 sharesMinted) {
        sharesMinted = assets;
        shares[account] += sharesMinted;
        totalShares += sharesMinted;
        emit Deposited(account, assets, sharesMinted);
    }
}
