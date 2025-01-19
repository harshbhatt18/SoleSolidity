// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract MotherStaker is ERC20, ERC20Permit {
    address public owner;

    constructor() ERC20("MotherStaker", "MSTK") ERC20Permit("MotherStaker") {
        owner = msg.sender;
        _mint(msg.sender, 10*10**18);
    }

    function mint(address to, uint256 amount) external {
        require(msg.sender == owner, "Only admin can mint");
        _mint(to, amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}