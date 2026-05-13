// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


// Fee-on-transfer token — takes 5% on every transfer
contract FeeToken {
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply;

    function mint(address to, uint amount) external {
        balanceOf[to] += amount;
        totalSupply += amount;
    }

    function approve(address spender, uint amount) external {
        allowance[msg.sender][spender] = amount;
    }

    function transferFrom(address from, address to, uint amount) external {
        require(allowance[from][msg.sender] >= amount, "not approved");
        allowance[from][msg.sender] -= amount;

        uint fee = amount * 5 / 100;
        uint actualAmount = amount - fee;

        balanceOf[from] -= amount;
        balanceOf[to] += actualAmount;
        totalSupply -= fee;
        // fee just disappears — burned
    }

    function transfer(address to, uint amount) external{
        require(balanceOf[msg.sender] >= amount);
        

        uint fee = amount * 5 / 100;
        uint actualAmount = amount - fee;

        
        totalSupply -= fee;
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += actualAmount;

    }

}

// Vulnerable vault
contract VulnerableVault {
    FeeToken public token;
    mapping(address => uint) public shares;
    uint public totalShares;
    uint public totalBalance;

    constructor(address _token) {
        token = FeeToken(_token);
    }

    function deposit(uint amount) external {
        // YOUR TASK — write the vulnerable version
        // use amount directly, not actual received
        require(amount > 0, "Must be more than Zero");

        
        token.transferFrom(msg.sender,address(this),amount);
        uint newShares;
        if(totalShares == 0 ){
        newShares = amount;
     
        }else{
        newShares = amount * totalShares/totalBalance;
        }
        shares[msg.sender] += newShares;
        totalShares += newShares;
        totalBalance += amount; 

    }

    function withdraw(uint shareAmount) external {
        // YOUR TASK — write withdraw
        // shares → proportional token amount → transfer out

        uint tokenAmount;
        require(shareAmount > 0, "Must be greater than Zero");
        require(shares[msg.sender] >= shareAmount, "You dont haeve any shares");

        tokenAmount = shareAmount * totalBalance/totalShares;

        shares[msg.sender] -= shareAmount;
        totalShares -= shareAmount;
        totalBalance -= tokenAmount;


        token.transfer(msg.sender, tokenAmount);


    }
}