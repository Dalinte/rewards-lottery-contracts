import { ethers } from "hardhat";

async function main() {
  const Ticket = await ethers.getContractFactory("Ticket");
  const ticket = await Ticket.deploy('Ticket', 'TCT', '10000');

  await ticket.deployed();

  console.log(`Ticket deploy success`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
