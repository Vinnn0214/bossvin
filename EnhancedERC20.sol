// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";

contract EnhancedERC20Token is ERC20, Ownable, Pausable, ERC20Burnable, ERC20Snapshot {
    mapping(address => bool) private _familyMembers;
    mapping(address => bool) private _whitelist;

    // Events for better traceability
    event AuthorizationGranted(address indexed familyMember);
    event AuthorizationRevoked(address indexed familyMember);
    event FundsTransferred(address indexed sender, address indexed recipient, uint256 amount);
    event EtherDeposited(address indexed sender, uint256 amount);
    event EtherWithdrawn(address indexed owner, uint256 amount);
    event TokensLocked(address indexed account, uint256 amount, uint256 releaseTime);
    event AddedToWhitelist(address indexed account);
    event RemovedFromWhitelist(address indexed account);

    struct Timelock {
        uint256 amount;
        uint256 releaseTime;
    }

    mapping(address => Timelock) private _timelocks;

    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply
    ) ERC20(name, symbol) Ownable() {
        _mint(msg.sender, initialSupply);
    }

    // Fallback function to accept Ether
    receive() external payable {
        emit EtherDeposited(msg.sender, msg.value);
    }

    // Pause all token transfers
    function pause() external onlyOwner {
        _pause();
    }

    // Unpause all token transfers
    function unpause() external onlyOwner {
        _unpause();
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

    // Burn tokens
    function burnTokens(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    // Take a snapshot
    function snapshot() external onlyOwner {
        _snapshot();
    }

    // Add an account to the whitelist
    function addToWhitelist(address account) external onlyOwner {
        require(!_whitelist[account], "Already whitelisted");
        _whitelist[account] = true;
        emit AddedToWhitelist(account);
    }

    // Remove an account from the whitelist
    function removeFromWhitelist(address account) external onlyOwner {
        require(_whitelist[account], "Not in whitelist");
        _whitelist[account] = false;
        emit RemovedFromWhitelist(account);
    }

    // Check if an account is whitelisted
    function isWhitelisted(address account) public view returns (bool) {
        return _whitelist[account];
    }

    // Lock tokens for a specific period
    function lockTokens(uint256 amount, uint256 releaseTime) external {
        require(releaseTime > block.timestamp, "Release time must be in the future");
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");
        _timelocks[msg.sender] = Timelock(amount, releaseTime);
        _burn(msg.sender, amount);
        emit TokensLocked(msg.sender, amount, releaseTime);
    }

    // Unlock tokens after the release time
    function unlockTokens() external {
        Timelock memory timelock = _timelocks[msg.sender];
        require(block.timestamp >= timelock.releaseTime, "Tokens are still locked");
        _mint(msg.sender, timelock.amount);
        delete _timelocks[msg.sender];
    }

    // Override _beforeTokenTransfer to include pause functionality
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Snapshot) {
        super._beforeTokenTransfer(from, to, amount);
        require(!paused(), "Token transfer while paused");
    }
}
