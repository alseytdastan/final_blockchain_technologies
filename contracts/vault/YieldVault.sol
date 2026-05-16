// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ERC4626} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC4626.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

/// @title YieldVault
/// @notice ERC-4626 tokenized vault over a single underlying ERC-20 asset.
contract YieldVault is ERC4626, Ownable {
    constructor(IERC20 asset_, address owner_) ERC4626(asset_) ERC20("DeFiHub Yield Vault", "dhYV") Ownable(owner_) {}

    /// @dev Mitigates ERC-4626 inflation attack (OpenZeppelin recommendation).
    function _decimalsOffset() internal pure override returns (uint8) {
        return 3;
    }
}
