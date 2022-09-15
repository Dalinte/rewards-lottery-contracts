// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Ticket is ERC20, Ownable  {
    constructor() ERC20('Ticket', 'TCT') Ownable() {
        _mint(msg.sender, 1000000000000000);
    }

     function decimals() public view virtual override returns (uint8) {
        return 0;
    }

    function mint (address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }
}