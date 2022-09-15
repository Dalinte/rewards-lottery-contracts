// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

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
  address[] private userList;

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

  WinnerProportions[] private winnerProportions;
  uint maxWinnerCount = 39;

  struct TicketDistributionStruct {
    address playerAddress;
    uint256 startIndex;
    uint256 endIndex;
  }
  TicketDistributionStruct[] private ticketDistribution;

  event PlayTheLottery(address ticketSender, uint amount, uint timestamp);
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

    _playerTicketDistribution();
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
    totalTicket += _amount;

    emit PlayTheLottery(_msgSender(), _amount, block.timestamp);
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
    uint[] memory arr = _createArray(totalTicket);
    uint rand = getRandomNumber(0, totalTicket - 1);
    uint[] memory winnerArr = _shuffle(arr, rand);
    uint winnerIndex = 0;

    for (uint i = 0; i < winnerProportions.length; i++) {
      for (uint j = 0; j < winnerProportions[i].userCount; j++) {
        if (winnerIndex == userList.length || winnerIndex == maxWinnerCount) {
          break;
        }
        uint winnerReward = winnerProportions[i].rewardPercent.mul(rewardTokenBalance()).div(100);
        address winnerAddress = findWinningAddress(winnerArr[winnerIndex]);
        winners[winnerIndex] = Winner(winnerAddress, winnerReward);
        winnerIndex++;
      }
    }

    winnersCount = winnerIndex;
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
    uint arrLength = numberArr.length;

    for (uint i = 0; i < arrLength; i++) {
        uint n = i + uint256(keccak256(abi.encodePacked(randomNumber))) % (arrLength - i);
        uint temp = numberArr[n];
        numberArr[n] = numberArr[i];
        numberArr[i] = temp;
    }

    return numberArr;
  }

  function _playerTicketDistribution () private {
    uint256 _ticketIndex = 0;

    for (uint256 i = _ticketIndex; i < userList.length; i++) {
      uint _ticketDistributionLength = ticketDistribution.length;
      address _playerAddress = userList[i];
      uint _numTickets = userTickets[_playerAddress];

      TicketDistributionStruct memory newDistribution = TicketDistributionStruct({
        playerAddress: _playerAddress,
        startIndex: _ticketIndex,
        endIndex: _ticketIndex + _numTickets - 1
      });

      if (_ticketDistributionLength > i) {
        ticketDistribution[i] = newDistribution;
      } else {
        ticketDistribution.push(newDistribution);
      }
      _ticketIndex = _ticketIndex + _numTickets;
    }
  }

  function _createArray (uint arrayLength) private pure returns(uint[] memory) {
    uint[] memory arr = new uint[](arrayLength);

    for (uint i = 0; i < arrayLength; i++) {
      arr[i] = i;
    }

    return arr;
  }

  function findWinningAddress(uint256 _winningTicketIndex) private view returns(address) {
    uint _winningPlayerIndex = findUpperBound(_winningTicketIndex);
    return ticketDistribution[_winningPlayerIndex].playerAddress;
  }

  function findUpperBound(uint _winningTicketIndex) private view returns (uint) {
        if (userList.length == 0) {
            return 0;
        }

        uint low = 0;
        uint high = userList.length;
        while (low < high) {
            uint256 mid = Math.average(low, high);

            if (ticketDistribution[mid].startIndex > _winningTicketIndex) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        if (low > 0 && ticketDistribution[low - 1].startIndex <= _winningTicketIndex && ticketDistribution[low - 1].endIndex >= _winningTicketIndex) {
            return low - 1;
        } else {
            return low;
        }
    }
}