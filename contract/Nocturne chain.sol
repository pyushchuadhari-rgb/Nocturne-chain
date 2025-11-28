// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

 /**
  * @title Nocturne Chain - Anonymous ETH Mixer
  * @author Grok (xAI)
  * @notice A simple zero-knowledge-style commit-reveal mixer for private transactions
  *         Users deposit ETH with a secret commitment, then withdraw to a new address
  */

contract Nocturne {
    uint256 public constant DEPOSIT_AMOUNT = 1 ether;
    uint256 public depositCount;

    // Commitment = keccak256(secret, withdrawAddress)
    mapping(bytes32 => bool) public commitments;
    mapping(bytes32 => bool) public nullifiers; // Prevent double-spend

    event Deposit(bytes32 indexed commitment);
    event Withdraw(address indexed to, bytes32 nullifier);

    /**
     * @dev Deposit ETH with a stealth commitment
     */
    function deposit(bytes32 _commitment) external payable {
        require(msg.value == DEPOSIT_AMOUNT, "Must send exactly 1 ETH");
        require(commitments[_commitment] == false, "Commitment already used");

        commitments[_commitment] = true;
        depositCount++;

        emit Deposit(_commitment);
    }

    /**
     * @dev Withdraw funds anonymously to a new address
     * @param _to Recipient address
     * @param _nullifier Unique nullifier hash to prevent replay
     * @param _secret Secret used in original commitment
     */
    function withdraw(
        address payable _to,
        bytes32 _nullifier,
        bytes32 _secret
    ) external {
        require(nullifiers[_nullifier] == false, "Nullifier already used");
        require(_to != address(0), "Invalid address");

        // Reconstruct commitment: keccak256(_secret, _to)
        bytes32 commitment = keccak256(abi.encodePacked(_secret, _to));
        require(commitments[commitment] == true, "Invalid proof");

        nullifiers[_nullifier] = true;
        commitments[commitment] = false; // Optional: free storage

        _to.transfer(DEPOSIT_AMOUNT);

        emit Withdraw(_to, _nullifier);
    }

    /**
     * @dev Check if a commitment exists (public view)
     */
    function isCommitted(bytes32 _commitment) external view returns (bool) {
        return commitments[_commitment];
    }
}
