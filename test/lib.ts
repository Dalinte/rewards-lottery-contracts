const { ethers } = require("hardhat");

const lib = async function () {
  const ERC20 = await ethers.getContractFactory("Ticket")
  const Ticket = await ERC20.deploy('Ticket', 'TCT', 10000000000)
  const RewardToken = await ERC20.deploy('Tether', 'USDT', 10000000000)
    
  const lotteryContract = await ethers.getContractFactory("Lottery")
  const Lottery = await lotteryContract.deploy(Ticket.address , RewardToken.address, 10000000000)

  return {
    Ticket,
    RewardToken,
    Lottery
  }
}

export default lib