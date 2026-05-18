// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

import {IPriceFeed} from "../interfaces/IPriceFeed.sol";

/// @title LendingPool
/// @notice Collateralized lending: LTV cap, health factor, linear interest, liquidation.
contract LendingPool is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    uint256 public constant BPS = 10_000;
    uint256 public constant SECONDS_PER_YEAR = 365 days;

    IERC20 public immutable collateralAsset;
    IERC20 public immutable borrowAsset;
    IPriceFeed public immutable collateralPriceFeed;

    uint256 public maxLtvBps;
    uint256 public liquidationThresholdBps;
    uint256 public borrowRateBpsPerYear;
    uint256 public liquidationBonusBps;

    struct Account {
        uint256 collateral;
        uint256 principal;
        uint256 lastAccrual;
    }

    mapping(address => Account) public accounts;

    event CollateralDeposited(address indexed user, uint256 amount);
    event CollateralWithdrawn(address indexed user, uint256 amount);
    event Borrowed(address indexed user, uint256 amount, uint256 totalDebt);
    event Repaid(address indexed user, uint256 amount, uint256 remainingDebt);
    event Liquidated(
        address indexed borrower, address indexed liquidator, uint256 debtRepaid, uint256 collateralSeized
    );

    error ZeroAmount();
    error InsufficientCollateral();
    error BorrowExceededLtv();
    error HealthyAccount();
    error InsufficientLiquidity();
    error InvalidPrice();

    constructor(
        address collateralAsset_,
        address borrowAsset_,
        address collateralPriceFeed_,
        address initialOwner,
        uint256 maxLtvBps_,
        uint256 liquidationThresholdBps_,
        uint256 borrowRateBpsPerYear_,
        uint256 liquidationBonusBps_
    ) Ownable(initialOwner) {
        collateralAsset = IERC20(collateralAsset_);
        borrowAsset = IERC20(borrowAsset_);
        collateralPriceFeed = IPriceFeed(collateralPriceFeed_);
        maxLtvBps = maxLtvBps_;
        liquidationThresholdBps = liquidationThresholdBps_;
        borrowRateBpsPerYear = borrowRateBpsPerYear_;
        liquidationBonusBps = liquidationBonusBps_;
    }

    function depositCollateral(uint256 amount) external nonReentrant {
        if (amount == 0) revert ZeroAmount();
        _accrueInterest(msg.sender);

        accounts[msg.sender].collateral += amount;
        collateralAsset.safeTransferFrom(msg.sender, address(this), amount);

        emit CollateralDeposited(msg.sender, amount);
    }

    function withdrawCollateral(uint256 amount) external nonReentrant {
        if (amount == 0) revert ZeroAmount();
        _accrueInterest(msg.sender);

        Account storage account = accounts[msg.sender];
        if (account.collateral < amount) revert InsufficientCollateral();

        account.collateral -= amount;
        if (!_isHealthy(msg.sender)) revert BorrowExceededLtv();

        collateralAsset.safeTransfer(msg.sender, amount);
        emit CollateralWithdrawn(msg.sender, amount);
    }

    function borrow(uint256 amount) external nonReentrant {
        if (amount == 0) revert ZeroAmount();
        _accrueInterest(msg.sender);

        if (borrowAsset.balanceOf(address(this)) < amount) revert InsufficientLiquidity();

        Account storage account = accounts[msg.sender];
        uint256 newDebt = account.principal + amount;
        if (!_withinLtv(msg.sender, newDebt)) revert BorrowExceededLtv();

        account.principal = newDebt;
        borrowAsset.safeTransfer(msg.sender, amount);

        emit Borrowed(msg.sender, amount, newDebt);
    }

    function repay(uint256 amount) external nonReentrant {
        if (amount == 0) revert ZeroAmount();
        _accrueInterest(msg.sender);

        Account storage account = accounts[msg.sender];
        uint256 debt = account.principal;
        uint256 repayAmount = amount > debt ? debt : amount;

        account.principal = debt - repayAmount;
        borrowAsset.safeTransferFrom(msg.sender, address(this), repayAmount);

        emit Repaid(msg.sender, repayAmount, account.principal);
    }

    function liquidate(address borrower, uint256 debtToCover) external nonReentrant {
        if (debtToCover == 0) revert ZeroAmount();
        _accrueInterest(borrower);

        Account storage account = accounts[borrower];
        uint256 debt = account.principal;
        if (debt < 1 || _isHealthy(borrower)) revert HealthyAccount();

        uint256 actualRepay = debtToCover > debt ? debt : debtToCover;
        uint256 collateralSeized = _collateralForDebt(actualRepay);
        if (collateralSeized > account.collateral) collateralSeized = account.collateral;

        account.principal = debt - actualRepay;
        account.collateral -= collateralSeized;

        borrowAsset.safeTransferFrom(msg.sender, address(this), actualRepay);
        collateralAsset.safeTransfer(msg.sender, collateralSeized);

        emit Liquidated(borrower, msg.sender, actualRepay, collateralSeized);
    }

    function totalDebt(address user) external view returns (uint256) {
        return _totalDebt(user);
    }

    /// @notice Health factor scaled by BPS (10000 = 1.0). Max uint if no debt.
    function healthFactor(address user) public view returns (uint256) {
        uint256 debt = _totalDebt(user);
        if (debt < 1) return type(uint256).max;

        uint256 collateralValue = _collateralValueInBorrowAsset(user);
        return (collateralValue * liquidationThresholdBps) / debt;
    }

    function _accrueInterest(address user) internal {
        Account storage account = accounts[user];
        if (account.principal < 1) {
            account.lastAccrual = block.timestamp;
            return;
        }

        uint256 elapsed = block.timestamp - account.lastAccrual;
        if (elapsed < 1) return;

        uint256 interest = (account.principal * borrowRateBpsPerYear * elapsed) / (BPS * SECONDS_PER_YEAR);
        account.principal += interest;
        account.lastAccrual = block.timestamp;
    }

    function _totalDebt(address user) internal view returns (uint256) {
        Account memory account = accounts[user];
        if (account.principal < 1) return 0;

        uint256 elapsed = block.timestamp - account.lastAccrual;
        uint256 interest = (account.principal * borrowRateBpsPerYear * elapsed) / (BPS * SECONDS_PER_YEAR);
        return account.principal + interest;
    }

    function _collateralValueInBorrowAsset(address user) internal view returns (uint256) {
        uint256 amount = accounts[user].collateral;
        if (amount < 1) return 0;

        int256 price = collateralPriceFeed.latestAnswer();
        if (price <= 0) revert InvalidPrice();

        uint256 priceScale = 10 ** collateralPriceFeed.decimals();
        // Collateral and borrow asset use 18 decimals; borrow token represents $1.
        return (amount * uint256(price)) / priceScale;
    }

    function _collateralForDebt(uint256 debtAmount) internal view returns (uint256) {
        int256 price = collateralPriceFeed.latestAnswer();
        if (price <= 0) revert InvalidPrice();

        uint256 priceScale = 10 ** collateralPriceFeed.decimals();
        uint256 debtWithBonus = debtAmount + (debtAmount * liquidationBonusBps) / BPS;

        return (debtWithBonus * priceScale) / uint256(price);
    }

    function _withinLtv(address user, uint256 newDebt) internal view returns (bool) {
        uint256 maxBorrow = (_collateralValueInBorrowAsset(user) * maxLtvBps) / BPS;
        return newDebt <= maxBorrow;
    }

    function _isHealthy(address user) internal view returns (bool) {
        return healthFactor(user) >= BPS;
    }
}
