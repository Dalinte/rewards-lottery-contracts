// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "hardhat/console.sol";

contract Lottery is Ownable {
  using SafeMath for uint256;

  IERC20 ticketToken;
  IERC20 rewardToken;
  uint256 public endTime;
  uint public totalTicket;

  enum LotteryStatuses {
    inProgress,
    completed
  }

  LotteryStatuses public lotteryStatus = LotteryStatuses.inProgress;

  mapping (address => uint256) public userTickets;
  address[] public userList;

  struct Winner {
    address userAddress;
    uint256 amount;
  }

  mapping (uint256 => Winner) public winners;
  uint256 public winnersCount = 0;

  event TicketSent(address ticketSender, uint256 amount);
  event LotteryCompleted();

  constructor (address _ticketAddress, address _rewardTokenAddress, uint256 _endTime) Ownable() {
    require(_endTime > block.timestamp, "Timestamp in the past");
    ticketToken = IERC20(_ticketAddress);
    rewardToken = IERC20(_rewardTokenAddress);
    endTime = _endTime;
  }

  function completeLottery () external onlyOwner {
    require(endTime <= block.timestamp, "The time is not up yet");
    require(lotteryStatus != LotteryStatuses.completed, "Lottery already complete");

    _generateWinners();
    rewardToken.approve(address(this), rewardTokenBalance());
    _sendRewardsToWinners();
    
    lotteryStatus = LotteryStatuses.completed;

    emit LotteryCompleted();
  }

  function playTheLottery (uint256 _amount) public {
    // require(endTime > block.timestamp, "Time's up");
    require(_amount > 0, "You need to send more than 0 ticket");
    uint256 allowance = ticketToken.allowance(_msgSender(), address(this));
    require(allowance >= _amount, "Check the token allowance");
    ticketToken.transferFrom(_msgSender(), address(this), _amount);
    if (userTickets[_msgSender()] == 0) userList.push(_msgSender());
    userTickets[_msgSender()] +=  _amount;
    totalTicket = _amount;

    emit TicketSent(_msgSender(), _amount);
  }

  function _sendRewardsToWinners () internal {
    for (uint i = 0; i < winnersCount; i++) {
      rewardToken.transferFrom(address(this), winners[i].userAddress, winners[i].amount);
    }
  }

  function rewardTokenBalance () public view returns(uint256) {
    return rewardToken.balanceOf(address(this));
  }

  function _generateWinners () internal {
    require(userList.length > 0, "There must be more than zero players");
    uint256 winnerNumber = getRandomNumber(0, userList.length - 1);
    winners[0] = Winner(userList[winnerNumber], rewardTokenBalance());
    winnersCount = 1;
  }

  function getRandomNumber (uint256 _startingValue, uint256 _endingValue) public view returns(uint256) {
    uint256 amountBLockAgo = endTime.sub(block.timestamp).div(3) % 255;
    uint256 randomInt = uint256(keccak256(abi.encodePacked(blockhash(block.number.sub(amountBLockAgo)))));
    uint256 range = _endingValue - _startingValue + 1;

    randomInt = randomInt % range;
    randomInt += _startingValue;

    return randomInt;
  }
}