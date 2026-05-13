// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";

// Interfaces
interface IUniswapV2Pair {
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
    function getReserves() external view returns (uint112, uint112, uint32);
}

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// Mock vulnerable lending protocol
// Uses UniV2 spot price as oracle — THIS is the victim
contract VulnerableLendingProtocol {
    IUniswapV2Pair public pair;
    IERC20 public collateralToken; // token0
    IERC20 public borrowToken; // token1

    mapping(address => uint256) public collateralDeposited;
    mapping(address => uint256) public borrowed;

    constructor(address _pair, address _collateral, address _borrow) {
        pair = IUniswapV2Pair(_pair);
        collateralToken = IERC20(_collateral);
        borrowToken = IERC20(_borrow);

        // fund the protocol with borrowable tokens
        // (done in test setup)
    }

    // reads SPOT price directly from UniV2 reserves — vulnerable
    function getCollateralPrice() public view returns (uint256) {
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        // price of token0 in terms of token1
        return uint256(reserve0) * 1e18 / uint256(reserve1);
    }

    function depositCollateral(uint256 amount) external {
        collateralToken.transferFrom(msg.sender, address(this), amount);
        collateralDeposited[msg.sender] += amount;
    }

    // allows borrowing up to 75% of collateral value
    function borrow(uint256 amount) external {
        uint256 collateralValue = collateralDeposited[msg.sender] * getCollateralPrice() / 1e18;
        uint256 maxBorrow = collateralValue * 75 / 100;
        require(borrowed[msg.sender] + amount <= maxBorrow, "undercollateralized");
        borrowed[msg.sender] += amount;
        borrowToken.transfer(msg.sender, amount);
    }
}

