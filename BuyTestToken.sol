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
    uint public sale_start = 9999999999;
    uint public sale_end = 9999999999;
    uint public min_contribution = 9999999999; // busd
    uint public max_contribution = 9999999999; // busd
    uint public remaining_tokens = 0; // srv
    uint public constant tokens_perbusd = 100*10**9;
    
    mapping (address => uint) max_allowance;
    mapping (address => uint256) contributions;
    
    event Purchased(address indexed _account, uint _amount);
    
    constructor(address token_address, address busd_address)
    {
        token = TestToken(token_address);
        busd_smc = IBEP20(busd_address);
    }
    
    function buyTokens(uint busd_amount) public
    {
        require(block.timestamp > sale_start && block.timestamp < sale_end, "sale not active");
        require(max_allowance[_msgSender()] >= busd_amount, "busd_amount exceeds max_allowance");
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
    
    function setSaleDetails(uint _sale_start, uint _sale_end, uint _min_contribution, uint _max_contribution, uint256 _remaining_tokens) public onlyOwner
	{
	    require(sale_start == 9999999999 && sale_end == 9999999999 && min_contribution == 9999999999 && max_contribution ==  9999999999 && remaining_tokens == 0, "sale details already set");
        require(_sale_end > _sale_start && _sale_start > block.timestamp &&  _max_contribution >= _min_contribution, "invalid arguments");
        sale_start = _sale_start;
        sale_end = _sale_end;
        min_contribution = _min_contribution;
        max_contribution = _max_contribution;
        remaining_tokens = _remaining_tokens;
	}
    
    function addToWhitelisted(address account, uint amount) public onlyOwner
    {
        max_allowance[account] = amount;
    }
    
    function removeFromWhitelisted(address account) public onlyOwner
    {
        max_allowance[account] = 0;
    }
    
    function withdraw() public onlyOwner
    {
        require(block.timestamp > sale_end, "sale is still active");
        busd_smc.transfer(owner(), busd_smc.balanceOf(address(this)));
    }
}
