const TronWeb = require('tronWeb')
const {config} = require('./deploy.config.ts')

async function main() {  
  const tronWeb = new TronWeb({
      fullHost: config.fullHost,
      privateKey: config.privateKey
  })

  const address = tronWeb.address.fromPrivateKey(config.privateKey)
  const addressInBase58 = 'TPhKt2mX7GU7RQZMpATxWoZuVikzr8tVUQ'
  const addressInHex = tronWeb.address.toHex(addressInBase58);
  console.log(addressInHex);
  
  const options = {
    feeLimit: 1000000000,
    callValue: 0,
    userFeePercentage: 100,
    originEnergyLimit: 100000,
    abi: config.artifacts.abi,
    bytecode: config.artifacts.bytecode,
    name: config.contractName
  }
  
  const deployContractResponse = await tronWeb.transactionBuilder.createSmartContract(options, address)
  const signedtxn = await tronWeb.trx.sign(deployContractResponse, config.privateKey)
  // const receipt = await tronWeb.trx.sendRawTransaction(signedtxn)

  // console.log('deploy receipt', receipt)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});