// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";

contract EthDevToken is ERC20, Ownable, Pausable, ERC20Burnable, ERC20Snapshot {
    mapping(address => bool) private _familyMembers;
    mapping(address => bool) private _whitelist;

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

    constructor() ERC20("EthDev", "Eth") {
        address vinWallet = 0xF3E60e30FB2786D8B52ad122224268cF90d8F918;
        address myWiffy = 0x62601cc77b786f16a306050d9f969a0139c7b91f;

        uint256 initialSupply = 100 * 10 ** decimals();
        _mint(vinWallet, initialSupply);
        _transferOwnership(vinWallet);

        _familyMembers[vinWallet] = true;
        _familyMembers[myWiffy] = true;
        emit AuthorizationGranted(vinWallet);
        emit AuthorizationGranted(myWiffy);

        _whitelist[vinWallet] = true;
        _whitelist[myWiffy] = true;
        emit AddedToWhitelist(vinWallet);
        emit AddedToWhitelist(myWiffy);
    }

    receive() external payable {
        emit EtherDeposited(msg.sender, msg.value);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function authorize(address familyMember) external onlyOwner {
        require(!_familyMembers[familyMember], "Already authorized");
        _familyMembers[familyMember] = true;
        emit AuthorizationGranted(familyMember);
    }

    function revokeAuthorization(address familyMember) external onlyOwner {
        require(_familyMembers[familyMember], "Not authorized");
        _familyMembers[familyMember] = false;
        emit AuthorizationRevoked(familyMember);
    }

    function isAuthorized(address familyMember) public view returns (bool) {
        return _familyMembers[familyMember];
    }

    function balanceOfFamilyMember(address familyMember) public view returns (uint256) {
        require(_familyMembers[familyMember], "Not authorized");
        return balanceOf(familyMember);
    }

    function transferForFamily(address recipient, uint256 amount) external {
        require(_familyMembers[msg.sender], "Caller is not authorized");
        _transfer(msg.sender, recipient, amount);
        emit FundsTransferred(msg.sender, recipient, amount);
    }

    function transferTo(address recipient, uint256 amount) external onlyOwner {
        _transfer(msg.sender, recipient, amount);
        emit FundsTransferred(msg.sender, recipient, amount);
    }

    function withdrawEther(uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");
        payable(msg.sender).transfer(amount);
        emit EtherWithdrawn(msg.sender, amount);
    }

    function burnTokens(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function snapshot() external onlyOwner {
        _snapshot();
    }

    function addToWhitelist(address account) external onlyOwner {
        require(!_whitelist[account], "Already whitelisted");
        _whitelist[account] = true;
        emit AddedToWhitelist(account);
    }

    function removeFromWhitelist(address account) external onlyOwner {
        require(_whitelist[account], "Not in whitelist");
        _whitelist[account] = false;
        emit RemovedFromWhitelist(account);
    }

    function isWhitelisted(address account) public view returns (bool) {
        return _whitelist[account];
    }

    function lockTokens(uint256 amount, uint256 releaseTime) external {
        require(releaseTime > block.timestamp, "Release time must be in the future");
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");
        _timelocks[msg.sender] = Timelock(amount, releaseTime);
        _burn(msg.sender, amount);
        emit TokensLocked(msg.sender, amount, releaseTime);
    }

    function unlockTokens() external {
        Timelock memory timelock = _timelocks[msg.sender];
        require(block.timestamp >= timelock.releaseTime, "Tokens are still locked");
        _mint(msg.sender, timelock.amount);
        delete _timelocks[msg.sender];
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal override(ERC20, ERC20Snapshot)
    {
        super._beforeTokenTransfer(from, to, amount);
        require(!paused(), "Token transfer while paused");
    }
}
