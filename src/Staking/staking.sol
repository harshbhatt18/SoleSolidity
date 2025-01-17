// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StakingContract is Ownable {
    IERC20 public stakingToken; // ERC20 token used for staking
    IERC20 public rewardToken;  // ERC20 token used for rewards
    uint public rewardRate;     // Reward rate: tokens per second per token staked
    uint public totalRewards;   // Total reward tokens available
    uint public totalStaked;    // Total tokens currently staked

    struct Stake {
        uint amount;        // Amount of tokens staked
        uint startTime;     // Timestamp when the stake started
    }

    mapping(address => Stake) public stakes;
    mapping(address => uint) public rewards;

    event Staked(address indexed user, uint amount);
    event Unstaked(address indexed user, uint amount, uint reward);
    event PoolReplenished(uint amount);
    event RewardRateUpdated(uint newRate);

    constructor(address _stakingToken, address _rewardToken, uint _rewardRate) Ownable(msg.sender) {
        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_rewardToken);
        rewardRate = _rewardRate; // Example: 0.1 reward token per second per staking token
    }

    // Replenish the reward pool with ERC20 tokens (onlyOwner)
    function replenishPool(uint _amount) external onlyOwner {
        require(_amount > 0, "Must send tokens to replenish pool");
        rewardToken.transferFrom(msg.sender, address(this), _amount);
        totalRewards += _amount;

        emit PoolReplenished(_amount);
    }

    // Stake ERC20 tokens into the contract
    function stake(uint _amount) external {
        require(_amount > 0, "Cannot stake 0 tokens");

        // Transfer staking tokens from the user to the contract
        stakingToken.transferFrom(msg.sender, address(this), _amount);

        // Update rewards for the user if they already have a stake
        if (stakes[msg.sender].amount > 0) {
            rewards[msg.sender] += calculateReward(msg.sender);
        }

        // Update stake information
        stakes[msg.sender].amount += _amount;
        stakes[msg.sender].startTime = block.timestamp;

        totalStaked += _amount;

        emit Staked(msg.sender, _amount);
    }

    // Calculate the pending reward for a user
    function calculateReward(address _user) public view returns (uint) {
        Stake memory stakeInfo = stakes[_user];
        uint stakingDuration = block.timestamp - stakeInfo.startTime;

        uint reward = (stakeInfo.amount * stakingDuration * rewardRate) / 1 ether;

        // Ensure rewards do not exceed the available pool
        return reward > totalRewards ? totalRewards : reward;
    }

    // Unstake ERC20 tokens and claim rewards
    function unstake() external {
        uint stakedAmount = stakes[msg.sender].amount;
        require(stakedAmount > 0, "No tokens staked");

        uint reward = calculateReward(msg.sender);

        // Update state
        totalRewards -= reward;
        totalStaked -= stakedAmount;

        stakes[msg.sender].amount = 0;
        stakes[msg.sender].startTime = 0;
        rewards[msg.sender] = 0;

        // Transfer staked tokens and rewards to the user
        stakingToken.transfer(msg.sender, stakedAmount);
        rewardToken.transfer(msg.sender, reward);

        emit Unstaked(msg.sender, stakedAmount, reward);
    }

    // Update the reward rate (onlyOwner)
    function updateRewardRate(uint _newRate) external onlyOwner {
        rewardRate = _newRate;

        emit RewardRateUpdated(_newRate);
    }
}