// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Fee-on-transfer token — takes 5% on every transfer
contract FeeToken {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    uint256 public totalSupply;

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
        totalSupply += amount;
    }

    function approve(address spender, uint256 amount) external {
        allowance[msg.sender][spender] = amount;
    }

    function transferFrom(address from, address to, uint256 amount) external {
        require(allowance[from][msg.sender] >= amount, "not approved");
        allowance[from][msg.sender] -= amount;

        uint256 fee = amount * 5 / 100;
        uint256 actualAmount = amount - fee;

        balanceOf[from] -= amount;
        balanceOf[to] += actualAmount;
        totalSupply -= fee;
        // fee just disappears — burned
    }

    function transfer(address to, uint256 amount) external {
        require(balanceOf[msg.sender] >= amount);

        uint256 fee = amount * 5 / 100;
        uint256 actualAmount = amount - fee;

        totalSupply -= fee;
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += actualAmount;
    }
}

// Vulnerable vault
contract VulnerableVault {
    FeeToken public token;
    mapping(address => uint256) public shares;
    uint256 public totalShares;
    uint256 public totalBalance;

    constructor(address _token) {
        token = FeeToken(_token);
    }

    function deposit(uint256 amount) external {
        // YOUR TASK — write the vulnerable version
        // use amount directly, not actual received
        require(amount > 0, "Must be more than Zero");

        token.transferFrom(msg.sender, address(this), amount);
        uint256 newShares;
        if (totalShares == 0) {
            newShares = amount;
        } else {
            newShares = amount * totalShares / totalBalance;
        }
        shares[msg.sender] += newShares;
        totalShares += newShares;
        totalBalance += amount;
    }

    function withdraw(uint256 shareAmount) external {
        // YOUR TASK — write withdraw
        // shares → proportional token amount → transfer out

        uint256 tokenAmount;
        require(shareAmount > 0, "Must be greater than Zero");
        require(shares[msg.sender] >= shareAmount, "You dont haeve any shares");

        tokenAmount = shareAmount * totalBalance / totalShares;

        shares[msg.sender] -= shareAmount;
        totalShares -= shareAmount;
        totalBalance -= tokenAmount;

        token.transfer(msg.sender, tokenAmount);
    }
}
