// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title POP33 Demo V2 – cykle + limit 10 aktywnych cykli per user (bez prawdziwych wpłat)
/// @notice Kontrakt DEMO do testów na Base Sepolia.
///         - Przycisk w UI wywołuje openNextAndJoin()
///         - Kontrakt zarządza cyklami, limitami i zapisuje uczestników.
///         - Brak prawdziwych płatności / wypłat – tylko struktura danych i eventy.
contract Pop33DemoV2 {
    struct Join {
        address user;
        uint256 cycleId;
        uint256 timestamp;
    }

    struct Cycle {
        uint256 id;
        uint256 openedAt;
        uint256 participantsCount;
        bool isOpen;
    }

    // Ustawienia DEMO (możesz je zmienić przed deployem, jeśli chcesz)
    uint256 public constant MAX_PARTICIPANTS_PER_CYCLE = 100;
    uint256 public constant MAX_ACTIVE_CYCLES_PER_USER = 10;

    // Globalna lista joinów
    Join[] public joins;

    // Cykl po ID
    mapping(uint256 => Cycle) public cycles;

    // Uczestnicy per cykl
    mapping(uint256 => address[]) public participantsByCycle;

    // Ile cykli zostało utworzonych (id 0..totalCycles-1)
    uint256 public totalCycles;

    // Aktualnie „aktywny” cykl, do którego zapisuje openNextAndJoin()
    uint256 public currentCycleId;

    // Ile aktywnych cykli ma dany użytkownik (do limitu 10)
    mapping(address => uint256) public activeCyclesCount;

    // Jakie cykle ma dany użytkownik (lista ID)
    mapping(address => uint256[]) public userCycles;

    event Joined(
        uint256 indexed cycleId,
        address indexed user,
        uint256 indexed joinId
    );

    event DrawExecuted(
        uint256 indexed cycleId,
        bytes32 requestId
    );

    /// @dev Inicjalizujemy pierwszy cykl przy deployu
    constructor() {
        _openNewCycle();
    }

    /// @notice Główna funkcja do użycia z UI.
    ///         - Pilnuje limitu 10 aktywnych cykli per user.
    ///         - Jeśli obecny cykl jest pełny lub zamknięty, otwiera nowy.
    ///         - Dodaje użytkownika do bieżącego cyklu.
    function openNextAndJoin() external {
        require(
            activeCyclesCount[msg.sender] < MAX_ACTIVE_CYCLES_PER_USER,
            "Max active cycles reached"
        );

        // Upewniamy się, że mamy otwarty cykl, do którego można dołączyć
        if (
            totalCycles == 0 ||
            !cycles[currentCycleId].isOpen ||
            cycles[currentCycleId].participantsCount >= MAX_PARTICIPANTS_PER_CYCLE
        ) {
            _openNewCycle();
        }

        Cycle storage current = cycles[currentCycleId];

        // Jeszcze raz defensywnie
        require(current.isOpen, "Current cycle not open");
        require(
            current.participantsCount < MAX_PARTICIPANTS_PER_CYCLE,
            "Current cycle is full"
        );

        // Zapis joinu globalnie
        joins.push(
            Join({
                user: msg.sender,
                cycleId: currentCycleId,
                timestamp: block.timestamp
            })
        );
        uint256 joinId = joins.length - 1;

        // Zapis uczestnika w cyklu
        participantsByCycle[currentCycleId].push(msg.sender);
        current.participantsCount += 1;

        emit Joined(currentCycleId, msg.sender, joinId);

        // Jeżeli to jest pierwsze wejście danego usera w ten cykl,
        // zwiększamy licznik aktywnych cykli i zapisujemy cykl na liście usera.
        if (_isFirstJoinInCycle(msg.sender, currentCycleId)) {
            activeCyclesCount[msg.sender] += 1;
            userCycles[msg.sender].push(currentCycleId);
        }

        // Jeśli po tym joinie cykl osiągnął max, zamykamy go
        if (current.participantsCount >= MAX_PARTICIPANTS_PER_CYCLE) {
            _closeCycle(currentCycleId);
        }
    }

    /// @notice Stub do wywołania „losowania” w cyklu (bez rzeczywistego randomness/logiki nagród).
    ///         - W DEMO możesz po prostu emitować event, ewentualnie zamykać cykl.
    function runDraw(uint256 cycleId) external {
        require(cycleId < totalCycles, "Invalid cycleId");

        bytes32 requestId = keccak256(
            abi.encodePacked(block.timestamp, msg.sender, cycleId, joins.length)
        );
        emit DrawExecuted(cycleId, requestId);

        // Opcjonalnie zamykamy cykl przy losowaniu (jeśli jeszcze otwarty)
        if (cycles[cycleId].isOpen) {
            _closeCycle(cycleId);
        }
    }

    /// @notice Zwraca liczbę wszystkich joinów.
    function totalJoins() external view returns (uint256) {
        return joins.length;
    }

    /// @notice Zwraca dane cyklu po ID.
    function getCycle(uint256 cycleId)
        external
        view
        returns (
            uint256 id,
            uint256 openedAt,
            uint256 participantsCount,
            bool isOpen
        )
    {
        require(cycleId < totalCycles, "Invalid cycleId");
        Cycle storage c = cycles[cycleId];
        return (c.id, c.openedAt, c.participantsCount, c.isOpen);
    }

    /// @notice Zwraca uczestników danego cyklu.
    function getCycleParticipants(uint256 cycleId)
        external
        view
        returns (address[] memory)
    {
        require(cycleId < totalCycles, "Invalid cycleId");
        return participantsByCycle[cycleId];
    }

    /// @notice Zwraca listę ID cykli, w których brał udział użytkownik.
    function getUserCycles(address user)
        external
        view
        returns (uint256[] memory)
    {
        return userCycles[user];
    }

    /// @notice Zwraca ile aktywnych cykli ma dany użytkownik.
    function getActiveCyclesCount(address user)
        external
        view
        returns (uint256)
    {
        return activeCyclesCount[user];
    }

    /// @notice Zwraca ID aktualnego cyklu.
    function getCurrentCycleId() external view returns (uint256) {
        return currentCycleId;
    }

    /// @dev Otwieramy nowy cykl.
    function _openNewCycle() internal {
        uint256 newId = totalCycles;

        cycles[newId] = Cycle({
            id: newId,
            openedAt: block.timestamp,
            participantsCount: 0,
            isOpen: true
        });

        currentCycleId = newId;
        totalCycles += 1;
    }

    /// @dev Zamykamy cykl i zdejmujemy „aktywne cykle” użytkownikom, którzy w nim byli.
    function _closeCycle(uint256 cycleId) internal {
        Cycle storage c = cycles[cycleId];
        if (!c.isOpen) return;

        c.isOpen = false;

        address[] storage parts = participantsByCycle[cycleId];
        for (uint256 i = 0; i < parts.length; i++) {
            address user = parts[i];
            if (activeCyclesCount[user] > 0) {
                activeCyclesCount[user] -= 1;
            }
        }
    }

    /// @dev Sprawdza, czy to pierwsze wejście usera w dany cykl.
    ///      (prosta implementacja DEMO – liniowe przeszukanie listy uczestników danego cyklu)
    function _isFirstJoinInCycle(address user, uint256 cycleId)
        internal
        view
        returns (bool)
    {
        address[] storage parts = participantsByCycle[cycleId];
        for (uint256 i = 0; i < parts.length; i++) {
            if (parts[i] == user) {
                return false;
            }
        }
        return true;
    }
}
