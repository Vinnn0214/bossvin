// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EnhancedERC20Token is ERC20, Ownable {
    mapping(address => bool) private _authorizedUsers;
    mapping(address => uint256) private _gasBalances;

    constructor(string memory name, string memory symbol, uint256 initialSupply) ERC20(name, symbol) {
        // Mint initial supply to the contract deployer (owner)
        _mint(msg.sender, initialSupply);
    }

    // Add an authorized user to access funds
    function authorizeUser(address user) external onlyOwner {
        _authorizedUsers[user] = true;
    }

    // Remove an authorized user
    function revokeUser(address user) external onlyOwner {
        _authorizedUsers[user] = false;
    }

    // Check if the address is authorized
    function isAuthorizedUser(address user) public view returns (bool) {
        return _authorizedUsers[user];
    }

    // Allow authorized users to transfer funds
    function transferForAuthorizedUser(address recipient, uint256 amount) external {
        require(_authorizedUsers[msg.sender], "Caller is not an authorized user");
        _transfer(msg.sender, recipient, amount);
    }

    // Allow the owner to transfer funds directly to any recipient
    function ownerTransfer(address recipient, uint256 amount) external onlyOwner {
        _transfer(msg.sender, recipient, amount);
    }

    // Allow users to deposit funds for gas payments
    function depositGasFunds() external payable {
        require(msg.value > 0, "Must deposit ETH for gas");
        _gasBalances[msg.sender] += msg.value;
    }

    // Allow the owner to pay gas fees on behalf of another user
    function payGasForTransaction(address user, uint256 gasAmount) external onlyOwner {
        require(_gasBalances[user] >= gasAmount, "Insufficient gas balance for user");
        _gasBalances[user] -= gasAmount;
        payable(tx.origin).transfer(gasAmount); // Pay gas to the transaction origin
    }

    // Check gas balance of a user
    function getGasBalance(address user) public view returns (uint256) {
        return _gasBalances[user];
    }

    // Allow users to withdraw unused gas funds
    function withdrawGasFunds(uint256 amount) external {
        require(_gasBalances[msg.sender] >= amount, "Insufficient gas balance");
        _gasBalances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    // Override transfer function to allow gas to be paid by the owner
    function transferWithGasSupport(address recipient, uint256 amount, bool gasPaidByOwner) external {
        if (gasPaidByOwner) {
            require(_authorizedUsers[msg.sender], "Caller is not an authorized user");
            _transfer(msg.sender, recipient, amount);
            // Owner pays gas via a specified mechanism (deduct from gas balance)
            if (_gasBalances[owner()] > 0) {
                uint256 estimatedGas = tx.gasprice * gasleft();
                require(_gasBalances[owner()] >= estimatedGas, "Owner has insufficient gas funds");
                _gasBalances[owner()] -= estimatedGas;
                payable(tx.origin).transfer(estimatedGas); // Refund gas cost to caller
            }
        } else {
            _transfer(msg.sender, recipient, amount);
        }
    }
}
