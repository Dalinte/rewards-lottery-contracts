const TronWeb = require('tronWeb')
const ticketAbi = require('../artifacts/contracts/ticket.sol/Ticket.json')
require('dotenv').config()

async function main() {
  const privateKey = process.env.TRON_WALLET_PRIVATE_KEY
  
  const tronWeb = new TronWeb({
      fullHost: 'https://nile.trongrid.io',
      privateKey: privateKey
  })

  const address = tronWeb.address.fromPrivateKey(privateKey)

  const options = {
    feeLimit: 1000000000,
    callValue: 0,
    userFeePercentage: 100,
    originEnergyLimit: 10,
    abi: ticketAbi.abi,
    bytecode: ticketAbi.bytecode,
    name:"Ticket"
  }
  
  const deployContractResponse = await tronWeb.transactionBuilder.createSmartContract(options, address)
  const signedtxn = await tronWeb.trx.sign(deployContractResponse, privateKey)
  const receipt = await tronWeb.trx.sendRawTransaction(signedtxn)

  console.log('receipt', signedtxn)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});