// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// OpenZeppelin imports (via raw GitHub links)
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/token/ERC20/ERC20.sol";
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/access/Ownable.sol";
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/security/Pausable.sol";
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/token/ERC20/extensions/ERC20Snapshot.sol";

contract EthDevToken is ERC20, Ownable, Pausable, ERC20Burnable, ERC20Snapshot {
    mapping(address => bool) private _familyMembers;
    mapping(address => bool) private _whitelist;

    event AuthorizationGranted(address indexed member);
    event AuthorizationRevoked(address indexed member);
    event FundsTransferred(address indexed to, uint256 amount);
    event AddedToWhitelist(address indexed user);
    event RemovedFromWhitelist(address indexed user);

    constructor() ERC20("EthDev", "Eth") {
        uint256 initialSupply = 100 * 10 ** decimals(); // 100 Eth
        _mint(msg.sender, initialSupply);

        // Add initial family members
        _familyMembers[0xF3E60e30FB2786D8B52ad122224268cF90d8F918] = true;
        _familyMembers[0x62601cc77b786f16a306050d9f969a0139c7b91f] = true;

        // Add to whitelist
        _whitelist[0xF3E60e30FB2786D8B52ad122224268cF90d8F918] = true;
        _whitelist[0x62601cc77b786f16a306050d9f969a0139c7b91f] = true;
    }

    modifier onlyFamily() {
        require(_familyMembers[msg.sender], "Not authorized family");
        _;
    }

    modifier onlyWhitelisted() {
        require(_whitelist[msg.sender], "Not whitelisted");
        _;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function snapshot() public onlyOwner {
        _snapshot();
    }

    function transfer(address to, uint256 amount) public override whenNotPaused onlyWhitelisted returns (bool) {
        return super.transfer(to, amount);
    }

    function grantFamilyAccess(address user) public onlyOwner {
        _familyMembers[user] = true;
        emit AuthorizationGranted(user);
    }

    function revokeFamilyAccess(address user) public onlyOwner {
        _familyMembers[user] = false;
        emit AuthorizationRevoked(user);
    }

    function addToWhitelist(address user) public onlyOwner {
        _whitelist[user] = true;
        emit AddedToWhitelist(user);
    }

    function removeFromWhitelist(address user) public onlyOwner {
        _whitelist[user] = false;
        emit RemovedFromWhitelist(user);
    }

    function isFamilyMember(address user) public view returns (bool) {
        return _familyMembers[user];
    }

    function isWhitelisted(address user) public view returns (bool) {
        return _whitelist[user];
    }

    function _update(address from, address to, uint256 value) internal override(ERC20) {
        super._update(from, to, value);
    }

    function _mint(address account, uint256 value) internal override(ERC20) {
        super._mint(account, value);
    }
}
