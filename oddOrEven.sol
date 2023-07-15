//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract oddOrEven {

    address payable public owner;
    uint256 public minimumBet;
    uint256 public maximumBet;
    uint256 public participationFee;
    uint256 public totalParticipants;
    uint256 private totalAmount;
    uint256 private totalBets;

    modifier _onlyOwner {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    enum BetType {Even, Odd}

    struct Bet {
        address payable player;
        BetType betType;
        uint amount;
    }

    event BetPlaced(address indexed player, BetType betType, uint amount);
    event GameResult(uint randomNumber, BetType winningBetType, uint totalAmount);

    mapping(uint256 => Bet) public bets;
    mapping(address => bool) public betPlaced;

    constructor(uint256 _minimumBet, uint256 _maximumBet, uint256 _participationFee) {
        owner = payable(msg.sender);
        minimumBet = _minimumBet;
        maximumBet = _maximumBet;
        participationFee = _participationFee;
    }

    function placeBet(uint _betType) public payable {
        BetType betType = BetType(_betType);
        require(msg.value >= minimumBet && msg.value <= maximumBet, "The amount must be within betting limit");
        require(!betPlaced[msg.sender], "You cannot place your bet again");
        require(address(this).balance - msg.value >= totalAmount, "Insufficient contract balance");
        require(betType == BetType.Even || betType == BetType.Odd, "Invalid bet made");

        bets[totalBets] = Bet(payable(msg.sender), betType, msg.value);
        betPlaced[msg.sender] = true;
        emit BetPlaced(msg.sender, betType, msg.value);

        totalBets++;
        totalAmount += msg.value;

    }

    function generateRandomNumber() private view returns( uint256 ) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, block.number))) % 100 + 1;
    }

    function distributeWinnings(BetType _winningBetType, uint256 randomNumber) private {
        uint256 totalWinningAmount = 0;
        uint256 winnerCount = 0;

        for (uint256 i = 0; i < totalBets; i++) {
            if (bets[i].betType == _winningBetType) {
                totalWinningAmount += bets[i].amount;
                winnerCount++;
            }
        }

        uint256 feeAmount = totalAmount - totalWinningAmount;
        owner.transfer(feeAmount);

        if (winnerCount > 0) {
            uint256 eachWinnerAmount = totalWinningAmount / winnerCount;

            for (uint256 i = 0; i < totalBets; i++) {
                if (bets[i].betType == _winningBetType) {
                    bets[i].player.transfer(eachWinnerAmount);
                }
            }
        }

        emit GameResult(randomNumber, _winningBetType, totalAmount);
        totalBets = 0;
        totalAmount = 0;
    }
    
    function ResultAnnouncement() external {
        require(totalBets > 0, "No bets placed");

        uint256 randomNumber = generateRandomNumber();
        BetType winningBetType = BetType(randomNumber % 2);

        distributeWinnings(winningBetType, randomNumber);
    }

    function withdrawParticipationFees() _onlyOwner external {
        owner.transfer(address(this).balance);
    }
}