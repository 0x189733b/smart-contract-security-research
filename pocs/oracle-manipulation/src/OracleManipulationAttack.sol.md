// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";

// Interfaces
interface IUniswapV2Pair {
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function getReserves() external view returns (uint112, uint112, uint32);
}

interface IERC20 {
    function balanceOf(address) external view returns (uint);
    function transfer(address, uint) external returns (bool);
    function approve(address, uint) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// Mock vulnerable lending protocol
// Uses UniV2 spot price as oracle — THIS is the victim
contract VulnerableLendingProtocol {
    IUniswapV2Pair public pair;
    IERC20 public collateralToken; // token0
    IERC20 public borrowToken;     // token1
    
    mapping(address => uint) public collateralDeposited;
    mapping(address => uint) public borrowed;
    
    constructor(address _pair, address _collateral, address _borrow) {
        pair = IUniswapV2Pair(_pair);
        collateralToken = IERC20(_collateral);
        borrowToken = IERC20(_borrow);
        
        // fund the protocol with borrowable tokens
        // (done in test setup)
    }
    
    // reads SPOT price directly from UniV2 reserves — vulnerable
    function getCollateralPrice() public view returns (uint) {
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        // price of token0 in terms of token1
        return uint(reserve0) * 1e18 / uint(reserve1);
    }
    
    function depositCollateral(uint amount) external {
        collateralToken.transferFrom(msg.sender, address(this), amount);
        collateralDeposited[msg.sender] += amount;
    }
    
    // allows borrowing up to 75% of collateral value
    function borrow(uint amount) external {
        uint collateralValue = collateralDeposited[msg.sender] 
            * getCollateralPrice() 
            / 1e18;
        uint maxBorrow = collateralValue * 75 / 100;
        require(borrowed[msg.sender] + amount <= maxBorrow, "undercollateralized");
        borrowed[msg.sender] += amount;
        borrowToken.transfer(msg.sender, amount);
    }
}

