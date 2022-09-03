// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Lottery is Ownable {
  IERC20 ticketToken;
  IERC20 rewardToken;
  uint256 public lotteryDuration;

  enum LotteryStatuses {
    notStarted,
    started,
    completed
  }

  LotteryStatuses public lotteryStatus = LotteryStatuses.notStarted;

  mapping (address => uint256) public userTickets;
  mapping (uint256 => address) public uniqueUser;

  struct Winner {
    address userAddress;
    uint256 amount;
  }

  mapping (uint256 => Winner) public winners;
  uint256 winnersCount = 0;

  event TicketSent(address ticketSender, uint256 amount);

  constructor (address _ticketAddress, address _rewardTokenAddress, uint256 _lotteryDuration) Ownable() {
    lotteryStatus = LotteryStatuses.started;
    ticketToken = IERC20(_ticketAddress);
    rewardToken = IERC20(_rewardTokenAddress);
    lotteryDuration = _lotteryDuration;
  }

  function completeLottery () external onlyOwner {
    require(lotteryStatus != LotteryStatuses.completed, "Lottery already complete");

    _generateWinners();
    _sendRewardsToWinners();
    
    lotteryStatus = LotteryStatuses.completed;
  }

  function playTheLottery (uint256 _amount) public {
    require(_amount > 0, "You need to send more than 0 ticket");
    uint256 allowance = ticketToken.allowance(_msgSender(), address(this));
    require(allowance >= _amount, "Check the token allowance");
    ticketToken.transferFrom(_msgSender(), address(this), _amount);
    // if (userTickets[_msgSender()] > 0) userCount++;

    emit TicketSent(_msgSender(), _amount);
  }

  function _sendRewardsToWinners () internal {
    for (uint i = 0; i <= winnersCount; i++) {
      rewardToken.transferFrom(address(this), winners[i].userAddress, winners[i].amount);
    }
  }

  function rewardTokenBalance () public view returns(uint256) {
    return rewardToken.balanceOf(address(this));
  }

  function _generateWinners () internal {
    // winners[0] = Winner(userTickets[0], 2);
    // winners[1] = Winner(address(), 1);
    // winnersCount = 2;
  }
}