require('dotenv').config()
const privateKey = process.env.TRON_WALLET_PRIVATE_KEY

const configTicket = {
  fullHost: 'https://nile.trongrid.io',
  artifacts: require('../artifacts/contracts/ticket.sol/Ticket.json'),
  contractName: 'Ticket',
  privateKey: privateKey
}

const configLottery = {
  fullHost: 'https://nile.trongrid.io',
  artifacts: require('../artifacts/contracts/lottery.sol/Lottery.json'),
  contractName: 'Lottery',
  privateKey: privateKey
}

const config = configTicket   // Поменяйте на configLottery, если нужно деплоить лотерею

export {
  config
}