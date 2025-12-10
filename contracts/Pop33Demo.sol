// DEPRECATED: old demo stub, do not deploy/use in new versions
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title POP33 Demo Stub
/// @notice Minimalny kontrakt do testów na Sepolia – bez docelowej logiki wypłat.
contract Pop33Demo {
    struct Join {
        address user;
        uint256 cycleId;
        uint256 timestamp;
    }

    // Prosta lista joinów tylko do podglądu / eventów
    Join[] public joins;

    event Joined(uint256 indexed cycleId, address indexed user, uint256 indexed joinId);
    event DrawExecuted(uint256 indexed cycleId, bytes32 requestId);

    /// @notice Uczestnik dołącza do wskazanego cyklu (tylko do celów DEMO).
    function join(uint256 cycleId) external {
        joins.push(Join({
            user: msg.sender,
            cycleId: cycleId,
            timestamp: block.timestamp
        }));

        uint256 joinId = joins.length - 1;
        emit Joined(cycleId, msg.sender, joinId);
    }

    /// @notice Stub do wywołania losowania (bez prawdziwego randomness).
    function runDraw(uint256 cycleId) external {
        bytes32 requestId = keccak256(
            abi.encodePacked(block.timestamp, msg.sender, cycleId, joins.length)
        );
        emit DrawExecuted(cycleId, requestId);
    }

    /// @notice Zwraca liczbę wszystkich joinów (pomocnicze do testów).
    function totalJoins() external view returns (uint256) {
        return joins.length;
    }
}
