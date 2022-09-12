// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract USDT is ERC20, Ownable  {
    constructor() ERC20('Tether USD', 'USDT') Ownable() {
        _mint(msg.sender, 30000000000000000000000000); // 30 млн
    }
}