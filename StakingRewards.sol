pragma solidity ^0.6.12;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.4.0/contracts/math/Math.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.4.0/contracts/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.4.0/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.4.0/contracts/token/ERC20/SafeERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.4.0/contracts/utils/ReentrancyGuard.sol";



import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.4.0/contracts/utils/Pausable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.4.0/contracts/access/Ownable.sol";
import "./IStakingReward.sol";
  

contract StakingRewards is
    ReentrancyGuard,
    Pausable,
    Ownable
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
    event Recovered(address token, uint256 amount);


    /* ========== STATE VARIABLES ========== */

    IERC20 public rewardsToken;
    IERC20 public stakingToken;

    uint256 public rewardPerTokenStored;
    uint256 public rewardableBlocks = 0 ;
    uint256 public poolStartingBlock = 0;
    uint256 public poolEndingBlock = 0;

    mapping(address => uint256) public userRewardPerBlockPaid;
    mapping(address => uint256) public rewards;

    uint256 public _totalSupply = 0;
    uint256 public _totalRewardSupply = 0;
    
    mapping(address => uint256) private _balances;
    mapping(address => uint256) public stakedAt;  // blockNumber when user staked his token.
    
    
    

    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
      //  lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
           // userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }


    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _rewardsToken,
        address _stakingToken
    ) public Ownable()  {
        rewardsToken = IERC20(_rewardsToken);
        stakingToken = IERC20(_stakingToken);
    }

    /* ========== VIEWS ========== */

    function totalSupply() external  view returns (uint256) {
        return _totalSupply.div(1e18);
    }

    function balanceOf(address account) external  view returns (uint256) {
        return _balances[account];
    }

    // function lastTimeRewardApplicable() public  view returns (uint256) {
    //     return Math.min(block.timestamp, periodFinish);
    // }


    function rewardPerBlock() public view returns (uint256) {
        
        return (_totalRewardSupply.div(rewardableBlocks));
    }

    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
       
       uint256 rpb = rewardPerBlock().mul(1e18);
       return (rpb.div(_totalSupply));
    
    }
    
    function totalStakedBlock(address account) public view returns (uint256){
        return (block.number.sub(stakedAt[account]));
    }

    function earned(address account) public view returns (uint256) {
        uint256 totalBlockStaked;
        
        if(stakedAt[account] == 0){
            return 0;
        }
        
        if(block.number > poolEndingBlock){
           totalBlockStaked = stakedAt[account].sub(poolEndingBlock);  
        }
        // totalBlockStaked = stakedAt[account].sub(block.number - 1 );
        totalBlockStaked = block.number.sub(stakedAt[account]);
        
        return (_balances[account]
        .div(1e18)
        .mul(rewardPerToken())
        .mul(totalBlockStaked));
    }

    // function getRewardForDuration() external view returns (uint256) {
    //     return rewardRate.mul(rewardsDuration);
    // }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function deposit(uint256 _amount)
        external
        nonReentrant
        whenNotPaused
        updateReward(msg.sender)
    {
         require(_totalRewardSupply != 0 , "pool not started yet");
        require(_amount > 0, "Cannot stake 0");
        _totalSupply = _totalSupply.add(_amount);
        _balances[msg.sender] = _balances[msg.sender].add(_amount);
        stakedAt[msg.sender] = block.number;
        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);
        emit Staked(msg.sender, _amount);
    }

    function withdraw(uint256 _amount)
        public
        nonReentrant
        updateReward(msg.sender)
    {
        require(_amount > 0, "Cannot withdraw 0");
        _totalSupply = _totalSupply.sub(_amount);
        _balances[msg.sender] = _balances[msg.sender].sub(_amount);
        stakingToken.safeTransfer(msg.sender, _amount);
        rewardWithdraw();
        emit Withdrawn(msg.sender, _amount);
    }

    function rewardWithdraw() public nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardsToken.safeTransfer(msg.sender, reward);
            userRewardPerBlockPaid[msg.sender] += reward;
            stakedAt[msg.sender] = block.number;
            emit RewardPaid(msg.sender, reward);
        }
    }

    function exit() external {
        withdraw(_balances[msg.sender]);
        rewardWithdraw();
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function startPool(uint256 _reward,uint256 _poolExpiryTime)
        external
        onlyOwner
    {
        
        uint256 balance = rewardsToken.balanceOf(address(this));
   
        require(_reward <= balance,"contract doesnt have enough reward token balance");
        _totalRewardSupply = _reward;
        poolStartingBlock= block.number;
        rewardableBlocks = rewardableBlocksAfterTimepoint(_poolExpiryTime);
        poolEndingBlock = block.number + rewardableBlocks;

   
        emit RewardAdded(_reward);
    }

 
    
    function rewardableBlocksAfterTimepoint (uint timepoint) public view
    returns (uint) {
        // returns the first block number after timepoint
        require(timepoint > block.timestamp,"timepoint smaller than current timestamp");
        uint256 timeDiff = timepoint - block.timestamp;
        uint256 b = ( timeDiff)/(1 seconds);
        
        return b;
}

}
