// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Lottery is Ownable {
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
    endTime = block.timestamp;    // Изменить на _endTime
  }

  function completeLottery () external onlyOwner {
    require(endTime <= block.timestamp, "The time is not up yet");
    require(lotteryStatus != LotteryStatuses.completed, "Lottery already complete");

    _generateWinners();
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
    rewardToken.approve(address(this), rewardTokenBalance());
    // rewardToken.transferFrom(address(this), winners[0].userAddress, winners[0].amount);
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

  function getRandomNumber (uint256 _startingValue, uint256 _endingValue) internal view returns(uint256) {   
    uint256 randomInt = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1))));
    uint256 range = _endingValue - _startingValue + 1;

    randomInt = randomInt % range;
    randomInt += _startingValue;

    return randomInt;
  }
}