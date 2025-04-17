// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EnhancedERC20Token is ERC20, Ownable {
    mapping(address => bool) private _familyMembers;

    // Events for better traceability
    event AuthorizationGranted(address indexed familyMember);
    event AuthorizationRevoked(address indexed familyMember);
    event FundsTransferred(address indexed sender, address indexed recipient, uint256 amount);
    event EtherDeposited(address indexed sender, uint256 amount);
    event EtherWithdrawn(address indexed owner, uint256 amount);

    constructor(string memory name, string memory symbol, uint256 initialSupply) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
    }

    // Fallback function to accept Ether
    receive() external payable {
        emit EtherDeposited(msg.sender, msg.value);
    }

    // Add a family member to access funds
    function authorize(address familyMember) external onlyOwner {
        require(!_familyMembers[familyMember], "Already authorized");
        _familyMembers[familyMember] = true;
        emit AuthorizationGranted(familyMember);
    }

    // Remove a family member
    function revokeAuthorization(address familyMember) external onlyOwner {
        require(_familyMembers[familyMember], "Not authorized");
        _familyMembers[familyMember] = false;
        emit AuthorizationRevoked(familyMember);
    }

    // Check if the address is a family member
    function isAuthorized(address familyMember) public view returns (bool) {
        return _familyMembers[familyMember];
    }

    // Get balance of a family member
    function balanceOfFamilyMember(address familyMember) public view returns (uint256) {
        require(_familyMembers[familyMember], "Not authorized");
        return balanceOf(familyMember);
    }

    // Allow family members to transfer funds
    function transferForFamily(address recipient, uint256 amount) external {
        require(_familyMembers[msg.sender], "Caller is not authorized");
        _transfer(msg.sender, recipient, amount);
        emit FundsTransferred(msg.sender, recipient, amount);
    }

    // General-purpose transfer function for the owner
    function transferTo(address recipient, uint256 amount) external onlyOwner {
        _transfer(msg.sender, recipient, amount);
        emit FundsTransferred(msg.sender, recipient, amount);
    }

    // Withdraw Ether collected by the contract
    function withdrawEther(uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");
        payable(msg.sender).transfer(amount);
        emit EtherWithdrawn(msg.sender, amount);
    }
}
