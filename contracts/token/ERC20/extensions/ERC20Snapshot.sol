// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../ERC20.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to create snapshots of the state of token balances at a given block.
 */
abstract contract ERC20Snapshot is ERC20 {
    mapping (uint256 => mapping(address => uint256)) private _snapshotBalances;
    mapping (uint256 => mapping(address => uint256)) private _snapshotAllowances;

    uint256 private _currentSnapshotId;

    /**
     * @dev Returns the current snapshot id.
     */
    function currentSnapshotId() public view returns (uint256) {
        return _currentSnapshotId;
    }

    /**
     * @dev Creates a snapshot and returns its id.
     */
    function snapshot() public returns (uint256) {
        _currentSnapshotId += 1;
        uint256 snapshotId = _currentSnapshotId;
        emit Snapshot(snapshotId);
        return snapshotId;
    }

    /**
     * @dev Returns the balance of `account` at the given snapshot id.
     */
    function balanceOfAt(address account, uint256 snapshotId) public view returns (uint256) {
        require(snapshotId <= _currentSnapshotId, "ERC20Snapshot: nonexistent snapshot");
        if (snapshotId == _currentSnapshotId) {
            return balanceOf(account);
        } else {
            return _snapshotBalances[snapshotId][account];
        }
    }

    /**
     * @dev Returns the allowance of `spender` for `owner` at the given snapshot id.
     */
    function allowanceAt(address owner, address spender, uint256 snapshotId) public view returns (uint256) {
        require(snapshotId <= _currentSnapshotId, "ERC20Snapshot: nonexistent snapshot");
        if (snapshotId == _currentSnapshotId) {
            return allowance(owner, spender);
        } else {
            return _snapshotAllowances[snapshotId][owner][spender];
        }
    }

    /**
     * @dev Hooks to update snapshot balances and allowances before every transfer and approval.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        if (_currentSnapshotId != 0) {
            _snapshotBalances[_currentSnapshotId][from] = balanceOf(from);
            _snapshotBalances[_currentSnapshotId][to] = balanceOf(to);
        }
    }

    function _beforeApproval(address owner, address spender, uint256 amount) internal virtual override {
        super._beforeApproval(owner, spender, amount);

        if (_currentSnapshotId != 0) {
            _snapshotAllowances[_currentSnapshotId][owner][spender] = allowance(owner, spender);
        }
    }

    /**
     * @dev Emitted when a snapshot is created.
     */
    event Snapshot(uint256 id);
}
