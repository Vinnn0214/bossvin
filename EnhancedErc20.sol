// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EnhancedERC20Token is ERC20, Ownable {
    mapping(address => bool) private _familyMembers;

    constructor(string memory name, string memory symbol, uint256 initialSupply) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
    }

    // Add a family member to access funds
    function addFamilyMember(address familyMember) external onlyOwner {
        _familyMembers[familyMember] = true;
    }

    // Remove a family member
    function removeFamilyMember(address familyMember) external onlyOwner {
        _familyMembers[familyMember] = false;
    }

    // Check if the address is a family member
    function isFamilyMember(address familyMember) public view returns (bool) {
        return _familyMembers[familyMember];
    }

    // Allow family members to withdraw funds
    function transferForFamily(address recipient, uint256 amount) external {
        require(_familyMembers[msg.sender], "Caller is not a family member");
        _transfer(msg.sender, recipient, amount);
    }
}
