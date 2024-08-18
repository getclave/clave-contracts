// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC20Metadata} from '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import {IClaveRegistry} from '../interfaces/IClaveRegistry.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

contract ZtaKeV2 is Ownable {
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

    IERC20Metadata public stakeToken;
    IERC20Metadata public rewardToken;
    IClaveRegistry public registry;

    uint256 private immutable stakeTokenDecimals;
    uint256 private immutable rewardTokenDecimals;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public balanceOf;

    event Staked(address indexed user, address indexed token, uint256 amount);
    event Withdrawn(address indexed user, address indexed token, uint256 amount);
    event RewardPaid(address indexed user, address indexed token, uint256 reward);

    constructor(
        uint256 _limitPerUser,
        uint256 _totalLimit,
        address _stakeToken,
        address _rewardToken,
        address _registry
    ) Ownable() {
        limitPerUser = _limitPerUser;
        totalLimit = _totalLimit;

        stakeToken = IERC20Metadata(_stakeToken);
        rewardToken = IERC20Metadata(_rewardToken);
        registry = IClaveRegistry(_registry);

        stakeTokenDecimals = 10 ** uint256(stakeToken.decimals());
        rewardTokenDecimals = 10 ** uint256(rewardToken.decimals());
    }

    modifier onlyClave() {
        require(registry.isClave(msg.sender), 'not clave account');
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
            (rewardRate * (lastTimeRewardApplicable() - updatedAt) * rewardTokenDecimals) /
            totalSupply;
    }

    /// @param _rate uint256 - Price rate of (rewardToken / stakeToken) scaled with 10000
    function getApy(uint256 _rate) public view returns (uint256) {
        if (totalSupply == 0) {
            return
                (rewardRate * 365 days * 100 * _rate * stakeTokenDecimals) /
                (totalLimit * 10000 * rewardTokenDecimals);
        }
        return
            (rewardRate * 365 days * 100 * _rate * stakeTokenDecimals) /
            (totalSupply * 10000 * rewardTokenDecimals);
    }

    function stake(uint256 _amount) external onlyClave updateReward(msg.sender) {
        require(_amount > 0, 'amount = 0');
        require(balanceOf[msg.sender] + _amount <= limitPerUser, 'exceeds limit per user');
        require(totalSupply + _amount <= totalLimit, 'exceeds total limit');
        balanceOf[msg.sender] += _amount;
        totalSupply += _amount;
        stakeToken.transferFrom(msg.sender, address(this), _amount);
        emit Staked(msg.sender, address(stakeToken), _amount);
    }

    function withdraw(uint256 _amount) external updateReward(msg.sender) {
        require(_amount > 0, 'amount = 0');
        require(balanceOf[msg.sender] >= _amount, 'insufficient balance');
        balanceOf[msg.sender] -= _amount;
        totalSupply -= _amount;
        stakeToken.transfer(msg.sender, _amount);
        emit Withdrawn(msg.sender, address(stakeToken), _amount);
    }

    function earned(address _account) public view returns (uint256) {
        return
            ((balanceOf[_account] * (rewardPerToken() - userRewardPerTokenPaid[_account])) /
                rewardTokenDecimals) + rewards[_account];
    }

    function getReward() external updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardToken.transfer(msg.sender, reward);
            emit RewardPaid(msg.sender, address(rewardToken), reward);
        }
    }

    function setRewardsDuration(uint256 _duration) external onlyOwner {
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
            rewardRate * duration <= rewardToken.balanceOf(address(this)),
            'reward amount > balance'
        );

        finishAt = block.timestamp + duration;
        updatedAt = block.timestamp;
    }

    function withdrawReward(uint256 _amount) external onlyOwner {
        require(_amount <= rewardToken.balanceOf(address(this)), 'exceeds balance');
        rewardToken.transfer(owner(), _amount);
    }

    function setLimitPerUser(uint256 _limitPerUser) external onlyOwner {
        limitPerUser = _limitPerUser;
    }

    function setTotalLimit(uint256 _totalLimit) external onlyOwner {
        totalLimit = _totalLimit;
    }

    function updateRegistry(address _registry) external onlyOwner {
        registry = IClaveRegistry(_registry);
    }

    function _min(uint256 x, uint256 y) private pure returns (uint256) {
        return x <= y ? x : y;
    }
}
