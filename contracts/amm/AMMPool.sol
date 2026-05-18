// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {Math} from "openzeppelin-contracts/contracts/utils/math/Math.sol";

import {LPToken} from "../token/LPToken.sol";

/// @title AMMPool
/// @notice Constant-product AMM (x*y=k) with 0.3% swap fee, LP tokens, and slippage protection.
contract AMMPool is ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 public constant FEE_NUMERATOR = 997;
    uint256 public constant FEE_DENOMINATOR = 1000;

    address public immutable tokenA;
    address public immutable tokenB;
    address public immutable creator;
    LPToken public immutable lpToken;

    uint256 public reserveA;
    uint256 public reserveB;

    event Mint(address indexed sender, uint256 amountA, uint256 amountB, uint256 liquidity);
    event Burn(address indexed sender, uint256 amountA, uint256 amountB, uint256 liquidity);
    event Swap(
        address indexed sender, address indexed tokenIn, address indexed tokenOut, uint256 amountIn, uint256 amountOut
    );

    error Expired();
    error InsufficientOutputAmount();
    error InsufficientLiquidity();
    error InsufficientLiquidityMinted();
    error InvalidToken();
    error InvalidCreator();
    error ZeroAmount();

    constructor(address _tokenA, address _tokenB, address _creator) {
        require(_tokenA != _tokenB, "IDENTICAL_TOKENS");
        require(_tokenA != address(0) && _tokenB != address(0), "ZERO_ADDRESS");
        if (_creator == address(0)) revert InvalidCreator();
        tokenA = _tokenA;
        tokenB = _tokenB;
        creator = _creator;
        lpToken = new LPToken(address(this));
    }

    function addLiquidity(uint256 amountADesired, uint256 amountBDesired, uint256 amountAMin, uint256 amountBMin)
        external
        nonReentrant
        returns (uint256 amountA, uint256 amountB, uint256 liquidity)
    {
        (amountA, amountB) = _quoteLiquidity(amountADesired, amountBDesired);
        if (amountA < amountAMin || amountB < amountBMin) revert InsufficientLiquidityMinted();

        _transferIn(tokenA, msg.sender, amountA);
        _transferIn(tokenB, msg.sender, amountB);

        liquidity = _mintLiquidity(msg.sender, amountA, amountB);
    }

    function removeLiquidity(uint256 liquidity, uint256 amountAMin, uint256 amountBMin)
        external
        nonReentrant
        returns (uint256 amountA, uint256 amountB)
    {
        if (liquidity == 0) revert ZeroAmount();

        uint256 totalLp = lpToken.totalSupply();
        amountA = (liquidity * reserveA) / totalLp;
        amountB = (liquidity * reserveB) / totalLp;

        if (amountA < amountAMin || amountB < amountBMin) revert InsufficientLiquidity();

        reserveA -= amountA;
        reserveB -= amountB;
        lpToken.burn(msg.sender, liquidity);

        _transferOut(tokenA, msg.sender, amountA);
        _transferOut(tokenB, msg.sender, amountB);

        emit Burn(msg.sender, amountA, amountB, liquidity);
    }

    function swapExactTokensForTokens(address tokenIn, uint256 amountIn, uint256 amountOutMin, uint256 deadline)
        external
        nonReentrant
        returns (uint256 amountOut)
    {
        if (block.timestamp > deadline) revert Expired();
        if (amountIn == 0) revert ZeroAmount();

        (address tokenOut, uint256 reserveIn, uint256 reserveOut) = _getReserves(tokenIn);
        if (tokenOut == address(0)) revert InvalidToken();

        _transferIn(tokenIn, msg.sender, amountIn);

        amountOut = _getAmountOut(amountIn, reserveIn, reserveOut);
        if (amountOut < amountOutMin) revert InsufficientOutputAmount();

        if (tokenIn == tokenA) {
            reserveA += amountIn;
            reserveB -= amountOut;
        } else {
            reserveB += amountIn;
            reserveA -= amountOut;
        }

        _transferOut(tokenOut, msg.sender, amountOut);

        emit Swap(msg.sender, tokenIn, tokenOut, amountIn, amountOut);
    }

    function getAmountOut(address tokenIn, uint256 amountIn) external view returns (uint256 amountOut) {
        (address tokenOut, uint256 reserveIn, uint256 reserveOut) = _getReserves(tokenIn);
        if (tokenOut == address(0)) revert InvalidToken();
        return _getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function k() external view returns (uint256) {
        return reserveA * reserveB;
    }

    function _quoteLiquidity(uint256 amountADesired, uint256 amountBDesired)
        internal
        view
        returns (uint256 amountA, uint256 amountB)
    {
        if (amountADesired == 0 || amountBDesired == 0) revert ZeroAmount();

        if (reserveA == 0 && reserveB == 0) {
            return (amountADesired, amountBDesired);
        }

        uint256 amountBOptimal = (amountADesired * reserveB) / reserveA;
        if (amountBOptimal <= amountBDesired) {
            return (amountADesired, amountBOptimal);
        }

        uint256 amountAOptimal = (amountBDesired * reserveA) / reserveB;
        return (amountAOptimal, amountBDesired);
    }

    function _mintLiquidity(address to, uint256 amountA, uint256 amountB) internal returns (uint256 liquidity) {
        uint256 totalLp = lpToken.totalSupply();

        if (totalLp == 0) {
            liquidity = Math.sqrt(amountA * amountB);
        } else {
            uint256 liquidityA = (amountA * totalLp) / reserveA;
            uint256 liquidityB = (amountB * totalLp) / reserveB;
            liquidity = liquidityA < liquidityB ? liquidityA : liquidityB;
        }

        if (liquidity == 0) revert InsufficientLiquidityMinted();

        reserveA += amountA;
        reserveB += amountB;
        lpToken.mint(to, liquidity);

        emit Mint(to, amountA, amountB, liquidity);
    }

    function _getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut)
        internal
        pure
        returns (uint256 amountOut)
    {
        if (amountIn == 0) revert ZeroAmount();
        if (reserveIn == 0 || reserveOut == 0) revert InsufficientLiquidity();

        uint256 amountInWithFee = amountIn * FEE_NUMERATOR;
        amountOut = (amountInWithFee * reserveOut) / (reserveIn * FEE_DENOMINATOR + amountInWithFee);
    }

    function _getReserves(address tokenIn)
        internal
        view
        returns (address tokenOut, uint256 reserveIn, uint256 reserveOut)
    {
        if (tokenIn == tokenA) {
            return (tokenB, reserveA, reserveB);
        }
        if (tokenIn == tokenB) {
            return (tokenA, reserveB, reserveA);
        }
        return (address(0), 0, 0);
    }

    function _transferIn(address token, address from, uint256 amount) internal {
        IERC20(token).safeTransferFrom(from, address(this), amount);
    }

    function _transferOut(address token, address to, uint256 amount) internal {
        IERC20(token).safeTransfer(to, amount);
    }
}
