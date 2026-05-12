# Fee-on-Transfer Token Used in Vault Causes Undercollateralization and Protocol Insolvency

**Severity:** High

## Root Cause

The vault contract does not account for Fee-on-Transfer tokens. It assumes that the full `amount` passed into `deposit()` will be received, but Fee-on-Transfer tokens deliver less than the transferred amount. The contract updates its internal accounting based on the input `amount` instead of the actual tokens received.

## Impact

The vault’s accounting breaks, leading to undercollateralization. Users get shortchanged on withdrawals, and in some cases the vault becomes insolvent, resulting in permanent loss of funds and TVL.

## Proof of Concept

```solidity
function testFeeOnTransferExploitTwo() public {
    // Alice deposits first
    vm.startPrank(alice);
    token.approve(address(vault), 50e18);
    vault.deposit(50e18);
    vm.stopPrank();

    // Bob deposits second
    vm.startPrank(bob);
    token.approve(address(vault), 50e18);
    vault.deposit(50e18);
    vm.stopPrank();

    console.log("Vault balance after both deposit:", token.balanceOf(address(vault)) / 1e18);
    console.log("Alice shares:", vault.shares(alice) / 1e18);
    console.log("Bob shares:", vault.shares(bob) / 1e18);
    console.log("Total shares:", vault.totalShares() / 1e18);

    // Alice withdraws successfully
    uint aliceShares = vault.shares(alice);
    vm.prank(alice);
    vault.withdraw(aliceShares);
    console.log("Alice final balance:", token.balanceOf(alice) / 1e18);

    // Bob cannot withdraw — vault is insolvent
    uint bobShares = vault.shares(bob);
    vm.expectRevert();
    vm.prank(bob);
    vault.withdraw(bobShares);
    console.log("Bob cannot withdraw, vault insolvent");
}

```

## Recommendation

Always measure the actual amount received instead of trusting the input amount.
```solidity

function deposit(uint amount) external {
    uint balanceBefore = token.balanceOf(address(this));
    
    token.transferFrom(msg.sender, address(this), amount);
    
    uint actualReceived = token.balanceOf(address(this)) - balanceBefore;
    
    // Use actualReceived, not amount
    uint shares = actualReceived * totalShares / totalBalance;
    _mint(msg.sender, shares);
}

```
