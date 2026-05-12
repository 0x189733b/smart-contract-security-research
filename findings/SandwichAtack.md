**Title:** swapExactTokensForTokens() uses amountOutMin = 0 enabling sandwich attacks that drain protocol yield 

**Severity:** Medium 

**Root cause:** 
High slippage tolerance in swapExactTokensForTokens function as well as the use of block.timestamp as the deadline 

**Impact:** 
Loss of yield to the protocol on every swap event. users receive  less than they are supposed to. The cumulative impact scales with the TVL and swap frequency

**Proof of concept:**
Due to the rootcauses above when the swapExactTokensForTokens function is called and is in the mempool anyone who sees this can call the function at a higher gas so theirs runs and submits a swap before them making the one who calls get a worse price due to slippage. The attacker can then backrun the transaction and make a profit by swapping the tokens they swapped in the first place

**Proof of Code:** is found in SandWichAttack.t.sol 


Pool:100,000 USDC rewards to compound Without attack: 100,000 USDC added to pool With sandwich: bot extracts 30,000 USDC Users receive: 70,000 USDC worth of yield Loss per event: 30%
 

**Recommendation:** 
Make the deadline a reasonable time away from the current block time like 15 minutes away and make the minimum amount close to the amount expected for example it can be at least 90% of the amount wanted this can be done by getting the amount the last path offers and getting 90% of this and making it the minimum amount
uint[] memory amountsOut = router.getAmountsOut(rewardAmount, path); uint amountOutMin = amountsOut[amountsOut.length - 1] * 90 / 100;

```solidity

uint[] memory amountsOut = router.getAmountsOut(rewardAmount, path);
uint expectedOut = amountsOut[amountsOut.length - 1];

// accept up to 10% slippage
uint amountOutMin = expectedOut * 90 / 100;

router.swapExactTokensForTokens(
    rewardAmount,
    amountOutMin,
    path,
    address(this),
    block.timestamp + 15 minutes
);

```
