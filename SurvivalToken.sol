// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./@openzeppelin/contracts/access/Ownable.sol";
import "./@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract SurvivalToken is ERC20, ERC20Burnable, Ownable 
{
	struct SaleStage
	{
	    uint start_epoch;
	    uint end_epoch;
	    uint cap;
	    uint minted;
	    address manager;
	    uint[] vesting_lock;
	}
	
	struct DevsVesting
	{
	    address account;
	    uint256 total_amount;
	    uint256 remaining_amount;
	    uint cliff_periods;
	    uint periods_count;
	    uint first_unlock;
	    uint period_unlock;
	}
	
	enum DevsVestingAccount { MARKETING, PARTNERSHIP, ADVISORY, TEAM, REWARDS, RESERVES }
	
	uint public first_unlock_epoch = 9999999999;
	uint public constant unlock_period = 30 days;
	
	mapping (address => uint256) remaining_balance;
	
	SaleStage privateA;
	mapping (address => uint256) privateA_contributions;
	uint256 public constant privateA_tokens_amount = 15000000*10**9;
	
	SaleStage privateBC;
	mapping (address => uint256) privateBC_contributions;
	uint256 public constant privateBC_tokens_amount = 145000000*10**9;
	
	uint256 public constant public_sale_tokens_amount = 5000000*10**9;
	
	address public constant marketing_tokens_account = 0x0A098Eda01Ce92ff4A4CCb7A4fFFb5A43EBC70DC; // <---- different value on mainnet
	uint256 public constant marketing_tokens_amount = 100000000*10**9;

	address public constant partnership_tokens_account = 0x03C6FcED478cBbC9a4FAB34eF9f40767739D1Ff7; // <---- different value on mainnet
	uint256 public constant partnership_tokens_amount = 60000000*10**9;

	address public constant advisory_tokens_account = 0x1aE0EA34a72D944a8C7603FfB3eC30a6669E454C; // <---- different value on mainnet
	uint256 public constant advisory_tokens_amount = 50000000*10**9;
		
	address public constant team_tokens_account = 0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB; // <---- different value on mainnet
	uint256 public constant team_tokens_amount = 75000000*10**9;
	
	address public constant game_rewards_account = 0x583031D1113aD414F02576BD6afaBfb302140225; // <---- different value on mainnet
	uint256 public constant game_rewards_amount = 450000000*10**9;
	
	address public constant game_reserves_account = 0xdD870fA1b7C4700F2BD7f44238821C26f7392148; // <---- different value on mainnet
	uint256 public constant game_reserves_amount = 100000000*10**9;
	
	DevsVesting[6] devs_tokens;
	
	constructor() ERC20("Survival Token", "SRV") 
	{
        uint arr_len = 12;
        uint[] memory vesting_lock = new uint[](arr_len);
        vesting_lock[0] = 9000;
        for(uint i=1; i<arr_len;i++)
        {
           vesting_lock[i] = vesting_lock[i-1] - 750;
        }
        privateA = SaleStage(0, 0, privateA_tokens_amount, 0, owner(), vesting_lock);
        
        arr_len = 12;
        vesting_lock = new uint[](arr_len);
        vesting_lock[0] = 9500;
        for(uint i=1; i<arr_len;i++)
        {
           vesting_lock[i] = vesting_lock[i-1] - 791;
        }
        privateBC = SaleStage(9999999999, 9999999999, privateBC_tokens_amount, 0, address(0), vesting_lock);
        
        _mint(owner(), public_sale_tokens_amount); // for public sale (IDO launchpad)
		devs_tokens[0] = DevsVesting(marketing_tokens_account, marketing_tokens_amount, marketing_tokens_amount, 0, 18, 10000, 555 );
        devs_tokens[1] = DevsVesting(partnership_tokens_account, partnership_tokens_amount, partnership_tokens_amount, 0, 18, 10000, 555 );
        devs_tokens[2] = DevsVesting(advisory_tokens_account, advisory_tokens_amount, advisory_tokens_amount, 5, 30, 10000, 333 );
        devs_tokens[3] = DevsVesting(team_tokens_account, team_tokens_amount, team_tokens_amount, 2, 30, 10000, 333 );
        devs_tokens[4] = DevsVesting(game_rewards_account, game_rewards_amount, game_rewards_amount, 0, 45, 10000, 222 );
		devs_tokens[5] = DevsVesting(game_reserves_account, game_reserves_amount, game_reserves_amount, 0, 12, 10000, 833 );
	}
	
	function addContributor(address account, uint256 amount, uint sale_stage) external
	{
	    if(sale_stage == 0)
	    { // privateA
            require(privateA.manager == _msgSender(), "caller does not have permission");
            require(privateA.minted + amount <= privateA.cap, "tokens sold out");
            remaining_balance[account] += amount;
            privateA.minted += amount;
            privateA_contributions[account] += amount;
	    }
	    else if(sale_stage == 1)
	    { // privateBC
            require(privateBC.manager == _msgSender(), "caller does not have permission");
            require(privateBC.start_epoch <= block.timestamp && privateBC.end_epoch >= block.timestamp, "sale not active");
            require(privateBC.minted + amount <= privateBC.cap, "tokens sold out");
            remaining_balance[account] += amount;
            privateBC.minted += amount;
            privateBC_contributions[account] += amount;
	    }

	}
	
	function setPrivateBCStartEndEpoch(uint start_epoch, uint end_epoch) public onlyOwner
	{
	    require(privateBC.start_epoch == 9999999999 && privateBC.end_epoch == 9999999999, "start_epoch/end_epoch already set");
        require(start_epoch > block.timestamp && end_epoch > start_epoch, "invalid arguments");
        privateBC.start_epoch = start_epoch;
        privateBC.end_epoch = end_epoch;
	}
	
	function setPrivateBCManager(address account) public onlyOwner
	{
	    privateBC.manager = account;
	}
	
	function setFirstUnlockEpoch(uint epoch) public onlyOwner
    {
        require(first_unlock_epoch == 9999999999, "first_unlock_epoch already set");
        require(epoch > block.timestamp, "epoch must be greater then current epoch");
        first_unlock_epoch = epoch;
    }
	
	function unclamedBalance(address account) public view returns(uint256)
    {
        return remaining_balance[account];
    }
	
	function getAvailvableBalance(address account) public view returns(uint256)
	{
	    uint256 balance = remaining_balance[account];
	    uint256 locked_amount = 0;
	    if(block.timestamp < first_unlock_epoch)
	    {
	        locked_amount += privateA_contributions[account];
	        locked_amount += privateBC_contributions[account];
	    }
	    else
	    {
	        uint epoch_index = (block.timestamp - first_unlock_epoch)/unlock_period;
	        if(epoch_index < privateA.vesting_lock.length)
	        {
	            locked_amount += (privateA_contributions[account]*privateA.vesting_lock[epoch_index])/10000; 
	        }
	        if(epoch_index < privateBC.vesting_lock.length)
	        {
	             locked_amount += (privateBC_contributions[account]*privateBC.vesting_lock[epoch_index])/10000;
	        }
	    }
	    return balance - locked_amount;
	}
	
	function claimToken() public
	{
        if(first_unlock_epoch+(privateA.vesting_lock.length)*unlock_period > block.timestamp)
        {
            uint256 availvable_balance = getAvailvableBalance(_msgSender());
            require(availvable_balance > 0, "insufficient balance");
            _mint(_msgSender(), availvable_balance);
            remaining_balance[_msgSender()] -= availvable_balance;
        }
        else
        {
            require(remaining_balance[_msgSender()] > 0, "insufficient balance");
            _mint(_msgSender(), remaining_balance[_msgSender()]);
            remaining_balance[_msgSender()] = 0;
        }
	}
	
	function withdraw(DevsVestingAccount index) public
	{
	    uint i = uint(index);
	    require(_msgSender() == devs_tokens[i].account && block.timestamp >= first_unlock_epoch + unlock_period*devs_tokens[i].cliff_periods);
	    uint periods_after_first_unlock = (block.timestamp - first_unlock_epoch - unlock_period*devs_tokens[i].cliff_periods)/unlock_period;
	    uint256 locked_amount = 0;
	    if(periods_after_first_unlock < devs_tokens[i].periods_count)
	    {
	         locked_amount = ((devs_tokens[i].first_unlock - devs_tokens[i].period_unlock*periods_after_first_unlock)*devs_tokens[i].total_amount)/10000;
	    }
	    require(devs_tokens[i].remaining_amount > locked_amount, "insufficient balance");
	    _mint(devs_tokens[i].account, devs_tokens[i].remaining_amount - locked_amount);
	    devs_tokens[i].remaining_amount = locked_amount;
	}
	
	function decimals() public view virtual override returns (uint8) 
	{
        return 9;
    }
}