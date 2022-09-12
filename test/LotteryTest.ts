const { expect } = require("chai");
const { ethers, network } = require("hardhat");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");

describe("Lottery contract", function () {

  async function deployTokenFixture() {
    const lotteryDuration = 60 * 60 // 1 час
    const lotteryEndTime = Math.floor(Date.now() / 1000) + lotteryDuration
    
    const [owner, ...addresses] = await ethers.getSigners()
    const ERC20 = await ethers.getContractFactory("Ticket")
    const Ticket = await ERC20.deploy('Ticket', 'TCT', 10000000000)
    const RewardToken = await ERC20.deploy('Tether', 'USDT', 10000000000)
      
    const lotteryContract = await ethers.getContractFactory("Lottery")
    const Lottery = await lotteryContract.deploy(Ticket.address , RewardToken.address, lotteryEndTime)

    return {
      owner, addresses, Ticket, RewardToken, Lottery
    }
  }

  // Сделайте getRandomNumber public, тогда тест можно запускать

  // it("getRandomNumber работает корректно", async function () {
  //   const { Lottery } = await loadFixture(deployTokenFixture);
    
  //   await network.provider.send("hardhat_mine", ["0x100"])

  //   expect(await Lottery.getRandomNumber(0, 1)).to.be.within(0, 1)
  //   expect(await Lottery.getRandomNumber(0, 0)).to.equal(0)
  //   expect(await Lottery.getRandomNumber(0, 1111)).to.be.within(0, 1111)
  //   expect(await Lottery.getRandomNumber(10, 10)).to.equal(10)
  //   expect(await Lottery.getRandomNumber(100, 1000)).to.be.within(100, 1000)
  // })

  it("Баланс токена-тикета при деплое весь у владельца контракта", async function () {
    const { Ticket, owner } = await loadFixture(deployTokenFixture);

    const ownerBalance = await Ticket.balanceOf(owner.address)
    expect(await Ticket.totalSupply()).to.equal(ownerBalance)
  })

  it("Завершение лотереи работает корректно", async function () {
    const { Ticket, RewardToken, Lottery, owner, addresses } = await loadFixture(deployTokenFixture)

    // Owner отправляет тикеты на адрес пользователя. Ожидается: баланс поменялся
    await expect(Ticket.transfer(addresses[1].address, 20)).to.changeTokenBalances(Ticket, [owner, addresses[1]], [-20, 20])
    await expect(Ticket.transfer(addresses[2].address, 20)).to.changeTokenBalances(Ticket, [owner, addresses[2]], [-20, 20])

     // Owner отправляет USDT на контракт лотереи. Ожидается: баланс поменялся
    await expect(RewardToken.transfer(Lottery.address, 100)).to.changeTokenBalances(RewardToken, [owner, Lottery.address], [-100, 100])

    // Пользователи дают разрешение контракту лотереи на трату тикетов
    await Ticket.connect(addresses[1]).approve(Lottery.address, 20)
    await Ticket.connect(addresses[2]).approve(Lottery.address, 20)
    
    // Ожидается: дано разрешение на трату тикетов контрактом лотереи у пользователей
    await expect(await Ticket.connect(addresses[1]).allowance(addresses[1].address, Lottery.address)).to.equal(20)
    await expect(await Ticket.connect(addresses[2]).allowance(addresses[1].address, Lottery.address)).to.equal(20)

    // Пользователь 1 переводит нажимает "Учавствовать лотерею"
    await Lottery.connect(addresses[1]).playTheLottery(5)
    await Lottery.connect(addresses[1]).playTheLottery(5)
    await Lottery.connect(addresses[1]).playTheLottery(5)
    await Lottery.connect(addresses[1]).playTheLottery(5)

    await Lottery.connect(addresses[2]).playTheLottery(5)

    // Ожидается: У пользователя 1 все его тикеты
    await expect(await Lottery.userTickets(addresses[1].address)).to.equal(20)
    await expect(await Lottery.userTickets(addresses[2].address)).to.equal(5)

    // Ожидается: Пользователь 1 записан в массив пользователей
    await expect(await Lottery.userList(0)).to.equal(addresses[1].address)
    
    const endTime = await Lottery.endTime()
    
    // Майнинг 256 блоков, чтобы функция генерации рандомного числа работала корректно в тестовой сети
    await network.provider.send("hardhat_mine", ["0x100"])
    await network.provider.send("evm_setNextBlockTimestamp", [+endTime])
    await Lottery.completeLottery()

    // Ожидается: Статус лотереи изменился на "Завершено"
    await expect(await Lottery.lotteryStatus()).to.equal(1)
    const usersCount = +await Lottery.usersCount()
    
    const winnerCount = +await Lottery.winnersCount()
    // Ожидается: победителей либо 35 штук, либо все пользователи
    await expect(winnerCount).to.be.oneOf([usersCount, 35]);

    const winner0 = await Lottery.winners(0)
    const winner1 = await Lottery.winners(1)
 

    expect(winner0.amount).to.equal(50)
    expect(winner1.amount).to.equal(5)

    // Ожидается: USDT отправлены победителю
    await expect(await RewardToken.balanceOf(winner0.userAddress)).to.equal(50)
    await expect(await RewardToken.balanceOf(winner1.userAddress)).to.equal(5)

    await expect(await Lottery.getUnusedRewards()).to.changeTokenBalances(RewardToken, [Lottery.address, owner], [-45, 45])
  })
})