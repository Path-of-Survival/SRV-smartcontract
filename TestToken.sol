// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./@openzeppelin/contracts/access/Ownable.sol";
import "./@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract TestToken is ERC20, ERC20Burnable, Ownable 
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
	
	enum DevsVestingAccount { PARTNERSHIP, MARKETING, TEAM, GAME }
	
	uint public first_unlock_epoch = 9999999999;
	uint public constant unlock_period = 30 days;
	
	mapping (address => uint256) remaining_balance;
	
	SaleStage seed_sale;
	mapping (address => uint256) seed_sale_contributions;
	
	SaleStage private_sale;
	mapping (address => uint256) private_sale_contributions;
    uint256 public constant private_sale_tokens_amount = 75000000*10**9;
	
	uint256 public constant public_sale_tokens_amount = 15000000*10**9;
	
	address public constant partnership_tokens_account = 0xBb7403aAF82342A0d987A8603aAf881136B5D125; // <---- different value on mainnet
	uint256 public constant partnership_tokens_amount = 60000000*10**9;
	
	address public constant marketing_tokens_account = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4; // <---- different value on mainnet
	uint256 public constant marketing_tokens_amount = 100000000*10**9;
	
	address public constant team_tokens_account = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4; // <---- different value on mainnet
	uint256 public constant team_tokens_amount = 75000000*10**9;
	
	address public constant game_rewards_account = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4; // <---- different value on mainnet
	uint256 public constant game_rewards_amount = 500000000*10**9;
	
	address public constant game_reserves_account = 0xF1F6720d4515934328896D37D356627522D97B49; // <---- different value on mainnet
	uint256 public constant game_reserves_amount = 100000000*10**9;
	
	DevsVesting[4] devs_tokens;
	
	constructor() ERC20("TestToken", "TEST") 
	{
        uint arr_len = 12;
        uint[] memory vesting_lock = new uint[](arr_len);
        vesting_lock[0] = 900;
        for(uint i=1; i<arr_len;i++)
        {
           vesting_lock[i] = vesting_lock[i-1] - 75;
        }
        seed_sale = SaleStage(0, block.timestamp + 3 days, 75000000*10**9, 0, owner(), vesting_lock);
        
        arr_len = 8;
        vesting_lock = new uint[](arr_len);
        vesting_lock[0] = 880;
        for(uint i=1; i<arr_len;i++)
        {
           vesting_lock[i] = vesting_lock[i-1] - 110;
        }
        private_sale = SaleStage(9999999999, 9999999999, private_sale_tokens_amount, 0, address(0), vesting_lock);
        
        _mint(owner(), public_sale_tokens_amount); // for public sale (IDO launchpad)
        _mint(game_reserves_account, game_reserves_amount);
        devs_tokens[0] = DevsVesting(partnership_tokens_account, partnership_tokens_amount, partnership_tokens_amount, 1, 7, 875, 125 );
        devs_tokens[1] = DevsVesting(marketing_tokens_account, marketing_tokens_amount, marketing_tokens_amount, 1, 7, 875, 125 );
        devs_tokens[2] = DevsVesting(team_tokens_account, team_tokens_amount, team_tokens_amount, 3, 30, 900, 30 );
        devs_tokens[3] = DevsVesting(game_rewards_account, game_rewards_amount, game_rewards_amount, 0, 49, 980, 20 );
	}
	
	function addContributor(address account, uint256 amount, uint sale_stage) external
	{
	    if(sale_stage == 0)
	    { // seed sale
            require(seed_sale.manager == _msgSender(), "caller does not have permission");
            require(seed_sale.minted + amount <= seed_sale.cap, "tokens sold out");
            remaining_balance[account] += amount;
            seed_sale.minted += amount;
            seed_sale_contributions[account] += amount;
	    }
	    else if(sale_stage == 1)
	    { // private sale
            require(private_sale.manager == _msgSender(), "caller does not have permission");
            require(private_sale.start_epoch <= block.timestamp && private_sale.end_epoch >= block.timestamp, "sale not active");
            require(private_sale.minted + amount <= private_sale.cap, "tokens sold out");
            remaining_balance[account] += amount;
            private_sale.minted += amount;
            private_sale_contributions[account] += amount;
	    }

	}
	
	function setPrivateSaleManager(address account) public onlyOwner
	{
	    private_sale.manager = account;
	}
	
	function setPrivateSaleStartEndEpoch(uint start_epoch, uint end_epoch) public onlyOwner
	{
	    require(private_sale.start_epoch == 9999999999 && private_sale.end_epoch == 9999999999, "start_epoch/end_epoch already set");
        require(start_epoch > block.timestamp && end_epoch > start_epoch, "invalid arguments");
        private_sale.start_epoch = start_epoch;
        private_sale.end_epoch = end_epoch;
	}
	
    function setPrivateSaleIDOShare(address account, uint256 amount) public onlyOwner
	{
	    require(private_sale.cap == private_sale_tokens_amount, "IDO share already set");
        require(private_sale.start_epoch > block.timestamp , "private_sale.start_epoch must be greater then current epoch");
        require(private_sale_tokens_amount >= amount , "invalid amount");
        private_sale.cap -= amount;
        _mint(account, amount);
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
	        locked_amount += seed_sale_contributions[account];
	        locked_amount += private_sale_contributions[account];
	    }
	    else
	    {
	        uint epoch_index = (block.timestamp - first_unlock_epoch)/unlock_period;
	        if(epoch_index < seed_sale.vesting_lock.length)
	        {
	            locked_amount += (seed_sale_contributions[account]*seed_sale.vesting_lock[epoch_index])/1000; 
	        }
	        if(epoch_index < private_sale.vesting_lock.length)
	        {
	             locked_amount += (private_sale_contributions[account]*private_sale.vesting_lock[epoch_index])/1000;
	        }
	    }
	    return balance - locked_amount;
	}
	
	function claimToken() public
	{
        if(first_unlock_epoch+(seed_sale.vesting_lock.length)*unlock_period > block.timestamp)
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
	         locked_amount = ((devs_tokens[i].first_unlock - devs_tokens[i].period_unlock*periods_after_first_unlock)*devs_tokens[i].total_amount)/1000;
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