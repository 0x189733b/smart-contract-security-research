# `swapExactTokensForTokens()` uses `amountOutMin = 0` Enabling Sandwich Attacks that Drain Protocol Yield

**Severity:** Medium

## Root Cause

High slippage tolerance in the `swapExactTokensForTokens()` function combined with the use of `block.timestamp` as the deadline.

## Impact

Attackers can consistently sandwich user swaps, causing loss of yield to the protocol on every swap event. Users receive significantly less tokens than expected. The cumulative loss scales with TVL and swap frequency.

## Proof of Concept

When a `swapExactTokensForTokens()` transaction is in the mempool, a searcher (bot) can frontrun it with a higher gas price to execute their swap first. This worsens the price for the original transaction. The bot then backruns the transaction to extract profit.

**Example Scenario (100,000 USDC rewards pool):**

- Without attack: 100,000 USDC added to pool
- With sandwich attack: Bot extracts **30,000 USDC**
- Users receive only **70,000 USDC** worth of yield
- **Loss per event:** ~30%

## Proof of Code

See `pocs/sandwich-attack/test/SandWichAttack.t.sol`

## Recommendation

Set a reasonable deadline (e.g. 15 minutes) and calculate a proper `amountOutMin` with acceptable slippage (e.g. 10%).

```solidity
uint[] memory amountsOut = router.getAmountsOut(rewardAmount, path);
uint expectedOut = amountsOut[amountsOut.length - 1];

// Accept up to 10% slippage
uint amountOutMin = expectedOut * 90 / 100;

router.swapExactTokensForTokens(
    rewardAmount,
    amountOutMin,
    path,
    address(this),
    block.timestamp + 15 minutes
);
