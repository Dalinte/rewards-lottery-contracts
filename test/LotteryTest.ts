const { expect } = require("chai");
const { ethers, network } = require("hardhat");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");

describe("Lottery contract", function () {

  async function deployTokenFixture() {
    const lotteryDuration = 60 * 60 // 1 час
    const lotteryEndTime = Math.floor(Date.now() / 1000) + lotteryDuration
    
    const [owner, ...addresses] = await ethers.getSigners()
    
    const TicketContract = await ethers.getContractFactory("Ticket")
    const Ticket = await TicketContract.deploy('Ticket', 'TCT', 10000000000)

    const USDTToken = await ethers.getContractFactory("USDT")
    const RewardToken = await USDTToken.deploy()
      
    const lotteryContract = await ethers.getContractFactory("Lottery")
    const Lottery = await lotteryContract.deploy(Ticket.address , RewardToken.address, lotteryEndTime)

    for (let i = 0; i < 50; i++) {
      let wallet = ethers.Wallet.createRandom()
      wallet = wallet.connect(ethers.provider)
      await owner.sendTransaction({to: wallet.address, value: ethers.utils.parseEther("1")});
      addresses.push(wallet)
    }
    console.log('end create wallets');
    
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

  // it("Баланс токена-тикета при деплое весь у владельца контракта", async function () {
  //   const { Ticket, owner } = await loadFixture(deployTokenFixture);

  //   const ownerBalance = await Ticket.balanceOf(owner.address)
  //   expect(await Ticket.totalSupply()).to.equal(ownerBalance)
  // })

  it("Завершение лотереи работает корректно", async function () {
    const lotteryReward = 120
    const userCount = 50

    const { Ticket, RewardToken, Lottery, owner, addresses } = await loadFixture(deployTokenFixture)
    
    for (let i = 1; i < userCount + 1; i++) {
      
       // Owner отправляет тикеты на адрес пользователя. Ожидается: баланс поменялся
      await expect(Ticket.transfer(addresses[i].address, 20)).to.changeTokenBalances(Ticket, [owner, addresses[i]], [-20, 20])

      // Пользователи дают разрешение контракту лотереи на трату тикетов
      await Ticket.connect(addresses[i]).approve(Lottery.address, 20)

         // Ожидается: дано разрешение на трату тикетов контрактом лотереи у пользователей
      await expect(await Ticket.connect(addresses[i]).allowance(addresses[i].address, Lottery.address)).to.equal(20)

      const rand = Math.floor(10)
      // Пользователь переводит нажимает "Учавствовать лотерею"
      await Lottery.connect(addresses[i]).playTheLottery(rand)

      // Ожидается: У пользователя все его тикеты
      await expect(await Lottery.userTickets(addresses[i].address)).to.equal(rand)
    }


     // Owner отправляет USDT на контракт лотереи. Ожидается: баланс поменялся
    await expect(RewardToken.transfer(Lottery.address, lotteryReward)).to.changeTokenBalances(RewardToken, [owner, Lottery.address], [-lotteryReward, lotteryReward])
    
    const endTime = await Lottery.endTime()
    
    // Майнинг 256 блоков, чтобы функция генерации рандомного числа работала корректно в тестовой сети
    await network.provider.send("hardhat_mine", ["0x100"])
    await network.provider.send("evm_setNextBlockTimestamp", [+endTime])

    let start = Date.now();
    console.log('Завершение лотереи...');
    await Lottery.completeLottery()
    let end = Date.now();
    console.log('Лотерея завершена за миллисекунд: ', end - start);
    

    // Ожидается: Статус лотереи изменился на "Завершено"
    await expect(await Lottery.lotteryStatus()).to.equal(1)
    const usersCount = +await Lottery.usersCount()
    
    const winnerCount = +await Lottery.winnersCount()
    // Ожидается: победителей либо 39 штук, либо все пользователи
    await expect(winnerCount).to.be.oneOf([usersCount, 39]);


    for (let i = 0; i < Math.min(userCount, 39); i++) {
      const winner = await Lottery.winners(i)
      console.log(`Победитель ${i}: `, winner.userAddress, +winner.amount)

      // Ожидается: USDT отправлены победителю
      // await expect(await RewardToken.balanceOf(winner.userAddress)).to.equal(+winner.amount)
    }

    // console.log('Неиспользуемые награды: ', +await Lottery.rewardTokenBalance());

    // await expect(await Lottery.getUnusedRewards()).to.changeTokenBalances(RewardToken, [Lottery.address, owner], [-45, 45])
  })
})