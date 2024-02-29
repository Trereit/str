// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RandomNumberGenerator {
    struct Commitment {
        bytes32 hash;
        uint256 revealBlock;
        uint256 value;
        bool revealed;
    }

    mapping(address => Commitment) public commitments;
    uint256 public revealWindow = 10; // Number of blocks for reveal phase
    uint256 public currentRound;
    uint256 public lastRevealBlock;

    event CommitmentSubmitted(address indexed sender, bytes32 indexed commitmentHash);
    event NumberRevealed(address indexed sender, uint256 indexed number);

    modifier onlyBeforeRevealPhase() {
        require(block.number < lastRevealBlock + revealWindow, "Reveal phase ended");
        _;
    }

    modifier onlyAfterRevealPhase() {
        require(block.number >= lastRevealBlock + revealWindow, "Reveal phase not ended");
        _;
    }

    function submitCommitment(bytes32 _hash) external {
        require(commitments[msg.sender].hash == bytes32(0), "Commitment already made");
        commitments[msg.sender] = Commitment(_hash, block.number + revealWindow, 0, false);
        emit CommitmentSubmitted(msg.sender, _hash);
    }

    function revealNumber(uint256 _number, bytes32 _secret) external onlyBeforeRevealPhase {
        bytes32 hash = keccak256(abi.encodePacked(_number, _secret));
        require(hash == commitments[msg.sender].hash, "Invalid commitment");

        commitments[msg.sender].value = _number;
        commitments[msg.sender].revealed = true;
        lastRevealBlock = block.number;
        emit NumberRevealed(msg.sender, _number);
    }

    function determineWinner() external onlyAfterRevealPhase returns (address) {
        uint256 winningNumber = uint256(blockhash(block.number - 1)) % 1000; // Use blockhash as randomness
        address winner;

        for (uint256 i = 0; i < currentRound; i++) {
            if (commitments[address(bytes32(uint256(uint160(address(this))) + i * 2))] // Pseudo-random address
                .value == winningNumber) {
                winner = address(bytes32(uint256(uint160(address(this))) + i * 2));
                break;
            }
        }

        currentRound++;
        return winner;
    }
}
