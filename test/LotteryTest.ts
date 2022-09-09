const { expect } = require("chai");
const { ethers, network } = require("hardhat");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");

describe("Lottery contract", function () {

  async function deployTokenFixture() {
    const lotteryDuration = 60 * 60 // 1 час
    const lotteryEndTime = Math.floor(Date.now() / 1000) + lotteryDuration
    
    const [owner, addr1, addr2] = await ethers.getSigners()
    const ERC20 = await ethers.getContractFactory("Ticket")
    const Ticket = await ERC20.deploy('Ticket', 'TCT', 10000000000)
    const RewardToken = await ERC20.deploy('Tether', 'USDT', 10000000000)
      
    const lotteryContract = await ethers.getContractFactory("Lottery")
    const Lottery = await lotteryContract.deploy(Ticket.address , RewardToken.address, lotteryEndTime)

    return {
      owner, addr1, addr2, Ticket, RewardToken, Lottery
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
    const { Ticket, RewardToken, Lottery, owner, addr1 } = await loadFixture(deployTokenFixture)

    // Owner отправляет тикеты на адрес пользователя. Ожидается: баланс поменялся
    await expect(Ticket.transfer(addr1.address, 20)).to.changeTokenBalances(Ticket, [owner, addr1], [-20, 20])

     // Owner отправляет USDT на контракт лотереи. Ожидается: баланс поменялся
    await expect(RewardToken.transfer(Lottery.address, 50)).to.changeTokenBalances(RewardToken, [owner, Lottery.address], [-50, 50])

    // Пользователь 1 дает разрешение контракту лотереи на трату тикетов 
    await Ticket.connect(addr1).approve(Lottery.address, 20)
    
    // Ожидается: дано разрешение на трату тикетов контрактом лотереи у пользователя 1
    await expect(await Ticket.connect(addr1).allowance(addr1.address, Lottery.address)).to.equal(20)

    // Пользователь 1 переводит нажимает "Учавствовать лотерею"
    await Lottery.connect(addr1).playTheLottery(5)

    // Ожидается: У пользователя 1 на балансе лотереии 5 тикетов
    await expect(await Lottery.userTickets(addr1.address)).to.equal(5)

    // Ожидается: Пользователь 1 записан в массив пользователей
    await expect(await Lottery.userList(0)).to.equal(addr1.address)

    
    const endTime = await Lottery.endTime()
    
    // Майнинг 256 блоков, чтобы функция генерации рандомного числа работала 
    await network.provider.send("hardhat_mine", ["0x100"])
    await network.provider.send("evm_setNextBlockTimestamp", [+endTime])

    await Lottery.completeLottery()

    // Ожидается: Статус лотереи изменился на "Завершено"
    await expect(await Lottery.lotteryStatus()).to.equal(1)
    
    // Ожидается: есть победители
    await expect(await Lottery.winnersCount()).to.equal(1)

    const winner0 = await Lottery.winners(0)
    
    // Ожидается: первый победитель - пользователь 1
    expect(winner0.userAddress).to.equal(addr1.address)
    expect(winner0.amount).to.equal(50)

    // Ожидается: USDT отправлены победителю
    await expect(await RewardToken.balanceOf(addr1.address)).to.equal(50)
  })
})