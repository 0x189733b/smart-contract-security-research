// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {FeeToken} from "../src/VulnerableVaultFOT.sol";
import {VulnerableVault} from "../src/VulnerableVaultFOT.sol";

contract FeeOnTransferTest is Test {
    FeeToken token;
    VulnerableVault vault;

    address alice = address(0x1);
    address bob = address(0x2);

    function setUp() public {
        token = new FeeToken();
        vault = new VulnerableVault(address(token));

        // give alice and bob 1000 tokens each
        token.mint(alice, 1000e18);
        token.mint(bob, 1000e18);
    }

    function testFeeOnTransferExploit() public {
        vm.startPrank(alice);
        uint initialBalanceOfAlice = token.balanceOf(alice);

        console.log(
            "The Initial Balance of Alice:",
            initialBalanceOfAlice / 1e18
        );
        vm.stopPrank();

        uint initialBalanceOfContract = token.balanceOf(address(vault));
        console.log("Current Balance of the Contract should be 0");
        console.log(
            "Initial Balance of Vault:",
            initialBalanceOfContract / 1e18
        );

        uint expectedAmount = 50e18;
        vm.startPrank(alice);
        token.approve(address(vault), expectedAmount);
        vault.deposit(50e18);

        uint currentbalanceOfAlice = token.balanceOf(alice);

        console.log("Current Balance of Alice:", currentbalanceOfAlice / 1e18);

        vm.stopPrank();

        uint currentBalanceOfContract = token.balanceOf(address(vault));

        console.log(
            "Current Balance of the Contract:",
            currentBalanceOfContract / 1e18
        );
        console.log("Amount to be sent:", expectedAmount / 1e18);
        console.log(
            "Difference",
            (expectedAmount - currentBalanceOfContract) / 1e18
        );

        assertLt(currentBalanceOfContract, expectedAmount);
    }


    function testFeeOnTransferExploitTwo() public {
    // alice deposits first
    vm.startPrank(alice);
    token.approve(address(vault), 50e18);
    vault.deposit(50e18);
    vm.stopPrank();

    // bob deposits second
    vm.startPrank(bob);
    token.approve(address(vault), 50e18);
    vault.deposit(50e18);
    vm.stopPrank();

    console.log("Vault balance after both deposit:", token.balanceOf(address(vault)) / 1e18);
    console.log("Alice shares:", vault.shares(alice) / 1e18);
    console.log("Bob shares:", vault.shares(bob) / 1e18);
    console.log("Total shares:", vault.totalShares() / 1e18);

    // both withdraw
  // alice withdraws successfully
uint aliceShares = vault.shares(alice);
vm.prank(alice);
vault.withdraw(aliceShares);
console.log("Alice final balance:", token.balanceOf(alice) / 1e18);

// bob cannot withdraw — vault is insolvent
uint bobShares = vault.shares(bob);
vm.expectRevert();
vm.prank(bob);
vault.withdraw(bobShares);
console.log("Bob cannot withdraw, vault insolvent");
}
}
