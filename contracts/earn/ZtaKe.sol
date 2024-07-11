// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IClaveRegistry} from '../interfaces/IClaveRegistry.sol';

contract ZtaKe {
    IERC20 public constant ZK = IERC20(0x5A7d6b2F92C77FAD6CCaBd7EE0624E64907Eaf3E);
    IClaveRegistry public registry1 = IClaveRegistry(0x8fcddcb5b3DE43267B89C4380A5EC8892C08D92C);
    IClaveRegistry public registry2 = IClaveRegistry(0x4A70d13c117fAC84c07917755aCcAE236f4DF97f);

    address public owner;

    // Maximum staking amount per user
    uint256 public limitPerUser;
    // Total staking limit
    uint256 public totalLimit;
    // Duration of rewards to be paid out (in seconds)
    uint256 public duration;
    // Timestamp of when the rewards finish
    uint256 public finishAt;
    // Minimum of last updated time and reward finish time
    uint256 public updatedAt;
    // Reward to be paid out per second
    uint256 public rewardRate;
    // Sum of (reward rate * dt * 1e18 / total supply)
    uint256 public rewardPerTokenStored;
    // Total staked
    uint256 public totalSupply;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public balanceOf;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    constructor(uint256 _limitPerUser, uint256 _totalLimit) {
        owner = msg.sender;
        limitPerUser = _limitPerUser;
        totalLimit = _totalLimit;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, 'not authorized');
        _;
    }

    modifier onlyClave() {
        require(
            registry1.isClave(msg.sender) || registry2.isClave(msg.sender),
            'not clave account'
        );
        _;
    }

    modifier updateReward(address _account) {
        rewardPerTokenStored = rewardPerToken();
        updatedAt = lastTimeRewardApplicable();

        if (_account != address(0)) {
            rewards[_account] = earned(_account);
            userRewardPerTokenPaid[_account] = rewardPerTokenStored;
        }

        _;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return _min(finishAt, block.timestamp);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }

        return
            rewardPerTokenStored +
            (rewardRate * (lastTimeRewardApplicable() - updatedAt) * 1e18) /
            totalSupply;
    }

    function getApy() public view returns (uint256) {
        if (totalSupply == 0) {
            return (rewardRate * 365 days * 100) / totalLimit;
        }
        return (rewardRate * 365 days * 100) / totalSupply;
    }

    function stake(uint256 _amount) external onlyClave updateReward(msg.sender) {
        require(_amount > 0, 'amount = 0');
        require(balanceOf[msg.sender] + _amount <= limitPerUser, 'exceeds limit per user');
        require(totalSupply + _amount <= totalLimit, 'exceeds total limit');
        balanceOf[msg.sender] += _amount;
        totalSupply += _amount;
        ZK.transferFrom(msg.sender, address(this), _amount);
        emit Staked(msg.sender, _amount);
    }

    function withdraw(uint256 _amount) external updateReward(msg.sender) {
        require(_amount > 0, 'amount = 0');
        require(balanceOf[msg.sender] >= _amount, 'insufficient balance');
        balanceOf[msg.sender] -= _amount;
        totalSupply -= _amount;
        ZK.transfer(msg.sender, _amount);
        emit Withdrawn(msg.sender, _amount);
    }

    function earned(address _account) public view returns (uint256) {
        return
            ((balanceOf[_account] * (rewardPerToken() - userRewardPerTokenPaid[_account])) / 1e18) +
            rewards[_account];
    }

    function getReward() external updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            ZK.transfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function setRewardsDuration(uint256 _duration) external onlyOwner {
        require(finishAt < block.timestamp, 'reward duration not finished');
        duration = _duration;
    }

    function notifyRewardAmount(uint256 _amount) external onlyOwner updateReward(address(0)) {
        if (block.timestamp >= finishAt) {
            rewardRate = _amount / duration;
        } else {
            uint256 remainingRewards = (finishAt - block.timestamp) * rewardRate;
            rewardRate = (_amount + remainingRewards) / duration;
        }

        require(rewardRate > 0, 'reward rate = 0');
        require(
            rewardRate * duration <= ZK.balanceOf(address(this)) - totalSupply,
            'reward amount > balance'
        );

        finishAt = block.timestamp + duration;
        updatedAt = block.timestamp;
    }

    function withdrawReward(uint256 _amount) external onlyOwner {
        require(_amount <= ZK.balanceOf(address(this)) - totalSupply, 'exceeds balance');
        ZK.transfer(owner, _amount);
    }

    function setLimitPerUser(uint256 _limitPerUser) external onlyOwner {
        limitPerUser = _limitPerUser;
    }

    function setTotalLimit(uint256 _totalLimit) external onlyOwner {
        totalLimit = _totalLimit;
    }

    function _min(uint256 x, uint256 y) private pure returns (uint256) {
        return x <= y ? x : y;
    }
}
