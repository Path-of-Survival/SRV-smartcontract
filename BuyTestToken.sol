// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./@openzeppelin/contracts/access/Ownable.sol";

interface IBEP20 
{
    function allowance(address _owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

interface TestToken 
{
   function addContributor(address account, uint256 amount, uint sale_stage) external;
}

contract BuyTestToken is Ownable
{
    TestToken private token; //srv
    IBEP20 private busd_smc;
    uint public sale_start;
    uint public sale_end;
    uint public constant min_contribution = 100; // 100 busd
    uint public constant max_contribution = 5000; // 1000 busd
    uint public remaining_tokens = 75000000*10**9; // srv
    uint public constant tokens_perbusd = 100*10**9;
    
    mapping (address => bool) whitelisted;
    mapping (address => uint256) contributions;
    
    event Purchased(address indexed _account, uint _amount);
    
    constructor(address token_address, address busd_address, uint sale_start_epoch, uint sale_end_epoch)
    {
        token = TestToken(token_address);
        busd_smc = IBEP20(busd_address);
        sale_start = sale_start_epoch;
        sale_end = sale_end_epoch;
    }
    
    function buyTokens(uint busd_amount) public
    {
        require(block.timestamp > sale_start && block.timestamp < sale_end, "sale not active");
        require(whitelisted[_msgSender()], "you are not whitelisted");
        require(busd_amount >= min_contribution && busd_amount <= max_contribution && contributions[_msgSender()] + busd_amount <= max_contribution, "invalid BUSD amount");
        uint busd_wei = busd_amount * 10**18;
        require(busd_smc.allowance(_msgSender(), address(this)) >= busd_wei, "busd amount exceeds allowance");
        uint tokens_amount = busd_amount*tokens_perbusd;
        require(remaining_tokens  >= tokens_amount, "tokens sold out");
        
        busd_smc.transferFrom(_msgSender(), address(this), busd_wei);
        token.addContributor(msg.sender, tokens_amount, 1);
        contributions[msg.sender] += busd_amount;
        remaining_tokens -= tokens_amount;
        emit Purchased(_msgSender(), tokens_amount);
    }
    
    function addToWhitelisted(address account) public onlyOwner
    {
        whitelisted[account] = true;
    }
    
    function removeFromWhitelisted(address account) public onlyOwner
    {
        whitelisted[account] = false;
    }
    
    function withdraw() public onlyOwner
    {
        busd_smc.transfer(owner(), busd_smc.balanceOf(address(this)));
    }
    
}
