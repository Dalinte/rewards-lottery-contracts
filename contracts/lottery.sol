// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "hardhat/console.sol";

contract Lottery is Ownable {
  using SafeMath for uint;

  IERC20 ticketToken;
  IERC20 rewardToken;
  uint public endTime;
  uint public totalTicket;

  enum LotteryStatuses {
    inProgress,
    completed
  }

  LotteryStatuses public lotteryStatus = LotteryStatuses.inProgress;

  mapping (address => uint) public userTickets;
  address[] public userList;

  struct Winner {
    address userAddress;
    uint amount;
  }

  mapping (uint => Winner) public winners;
  uint public winnersCount = 0;

  struct WinnerProportions {
    uint rewardPercent;
    uint userCount;
  }

  WinnerProportions[] internal winnerProportions;

  event TicketSent(address ticketSender, uint amount, uint timestamp);
  event LotteryCompleted();

  constructor (address _ticketAddress, address _rewardTokenAddress, uint _endTime) Ownable() {
    require(_endTime > block.timestamp, "Timestamp in the past");
    ticketToken = IERC20(_ticketAddress);
    rewardToken = IERC20(_rewardTokenAddress);
    endTime = _endTime;

    winnerProportions.push(WinnerProportions(50, 1));
    winnerProportions.push(WinnerProportions(5, 3));
    winnerProportions.push(WinnerProportions(1, 35));
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

  function playTheLottery (uint _amount) public {
    require(endTime > block.timestamp, "Time's up");
    require(_amount > 0, "You need to send more than 0 ticket");
    uint allowance = ticketToken.allowance(_msgSender(), address(this));
    require(allowance >= _amount, "Check the token allowance");
    ticketToken.transferFrom(_msgSender(), address(this), _amount);
    if (userTickets[_msgSender()] == 0) userList.push(_msgSender());
    userTickets[_msgSender()] +=  _amount;
    totalTicket = _amount;

    emit TicketSent(_msgSender(), _amount, block.timestamp);
  }

  function _sendRewardsToWinners () internal {
    for (uint i = 0; i < winnersCount; i++) {
      rewardToken.transferFrom(address(this), winners[i].userAddress, winners[i].amount);
    }
  }

  function rewardTokenBalance () public view returns(uint) {
    return rewardToken.balanceOf(address(this));
  }

   function usersCount () public view returns(uint) {
    return userList.length;
  }

  function getUnusedRewards () public onlyOwner {
    require(lotteryStatus == LotteryStatuses.completed, "The lottery has not been completed yet");
    require(rewardTokenBalance() != 0, "The rewards are all sent");

    rewardToken.transferFrom(address(this), address(owner()), rewardTokenBalance());
  }

  function _generateWinners () internal {
    require(userList.length > 0, "There must be more than zero players");
    uint[] memory arr = _createArray(userList.length);
    uint rand = getRandomNumber(0, userList.length - 1);
    uint[] memory winnerArr = _shuffle(arr, rand);

    uint arrCount = 0;

    for (uint i = 0; i < winnerProportions.length; i++) {
        for (uint j = 0; j < winnerProportions[i].userCount; j++) {
           if (arrCount == winnerArr.length) {
            winnersCount = arrCount;
            break;
          }
          uint winnerReward = winnerProportions[i].rewardPercent.mul(rewardTokenBalance()).div(100);
          winners[i] = Winner(userList[winnerArr[i]], winnerReward);
          arrCount++;
        }
      }

      winnersCount = arrCount;
  }

  function getRandomNumber (uint _startingValue, uint _endingValue) internal view returns(uint) {
    uint amountBlockAgo = endTime.sub(block.timestamp).div(3);
    uint safeAmountBLockAgo = amountBlockAgo % 254;
    uint randomInt = uint(keccak256(abi.encodePacked(blockhash(block.number.sub(safeAmountBLockAgo + 1)))));
    uint range = _endingValue - _startingValue + 1;

    randomInt = randomInt % range;
    randomInt += _startingValue;

    return randomInt;
  }

  function _shuffle (uint[] memory numberArr, uint randomNumber) internal pure returns (uint[] memory) {
    for (uint i = 0; i < numberArr.length; i++) {
        uint n = i + uint(keccak256(abi.encodePacked(randomNumber))) % (numberArr.length - i);
        uint temp = numberArr[n];
        numberArr[n] = numberArr[i];
        numberArr[i] = temp;
    }

    return numberArr;
  }

  function _createArray (uint arrayLength) internal pure returns(uint[] memory) {
    uint[] memory arr = new uint[](arrayLength);

    for (uint i = 0; i < arrayLength; i++) {
      arr[i] = i;
    }

    return arr;
  }
}