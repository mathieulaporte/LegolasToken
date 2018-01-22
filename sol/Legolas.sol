pragma solidity ^0.4.18;

import "./EIP20.sol";


contract Legolas is EIP20 {

    string  constant NAME = "Legolas Token";
    string  constant SYMBOL = "LGO";
    uint8   constant DECIMALS = 8;
    uint256 constant UNIT = 10**uint256(DECIMALS);

    uint256 constant ADVISORS_AMOUNT =   8750000 * UNIT;
    uint256 constant FOUNDERS_AMOUNT =  26250000 * UNIT;
    uint256 constant HOLDERS_AMOUNT  = 105000000 * UNIT;
    uint256 constant RESERVE_AMOUNT  =  35000000 * UNIT;
    uint256 constant INITIAL_AMOUNT  = 175000000 * UNIT;
    uint256 constant BONUS_AMOUNT    =  35000000 * UNIT;

    uint256 public advisorsAllocatedAmount = 0;
    uint256 public foundersAllocatedAmount = 0;
    uint256 public holdersAllocatedAmount = 0;
    address[] initialHolders;
    mapping (uint256 => bool) bonusNotDistributed;


    function Legolas() EIP20(
        INITIAL_AMOUNT + BONUS_AMOUNT,
        NAME,
        DECIMALS,
        SYMBOL
    ) public {
        bonusNotDistributed[1534291200] = true; // Wed, 15 Aug 2018 00:00:00 +0000
        bonusNotDistributed[1550188800] = true; // Fri, 15 Feb 2019 00:00:00 +0000
        bonusNotDistributed[1565827200] = true; // Thu, 15 Aug 2019 00:00:00 +0000
        bonusNotDistributed[1581724800] = true; // Sat, 15 Feb 2020 00:00:00 +0000
    }

    function allocate(address _address, uint256 _amount, uint8 _type) public onlyOwner returns (bool success) {
        // one allocations by address
        require(allocations[_address] == 0);

        if (_type == 0) {
            require(advisorsAllocatedAmount + _amount <= ADVISORS_AMOUNT);
            advisorsAllocatedAmount += _amount;
            advisors[_address] = true;
        } else if (_type == 1) {
            require(foundersAllocatedAmount + _amount <= FOUNDERS_AMOUNT);
            foundersAllocatedAmount += _amount;
            founders[_address] = true;
        } else {
            require(holdersAllocatedAmount + _amount <= HOLDERS_AMOUNT + RESERVE_AMOUNT);
            holdersAllocatedAmount += _amount;
        }

        allocations[_address] = _amount;
        balances[_address] += _amount;
        eligibleForBonus[_address] = true;
        initialHolders.push(_address);

        return true;
    }

    function distributeHolderBonus(uint256 bonusDate) public returns (bool success) {
        require(bonusDate <= now);
        require(bonusNotDistributed[bonusDate]);

        uint256 unspentAmount = 0;
        for (uint256 i = 0; i < initialHolders.length; i++) {
            if (eligibleForBonus[initialHolders[i]]) {
                unspentAmount += allocations[initialHolders[i]];
            }
        }
        uint256 bonusByLgo = (BONUS_AMOUNT / 4) / unspentAmount;

        for (uint256 j = 0; j < initialHolders.length; j++) {
            if (eligibleForBonus[initialHolders[j]]) {
                balances[initialHolders[j]] += allocations[initialHolders[j]] * bonusByLgo;
            }
        }

        bonusNotDistributed[bonusDate] = false;
        return true;
    }
}
