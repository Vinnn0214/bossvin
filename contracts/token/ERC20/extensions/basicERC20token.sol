// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Importing ERC20 interface
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BasicERC20Token is ERC20 {
    constructor(uint256 initialSupply) ERC20("BasicERC20", "BEC") {
        _mint(msg.sender, initialSupply);
    }

    // Add custom functions or overrides here if needed
}
