pragma solidity ^0.4.18;

import "./EIP20.sol";


contract Legolas is EIP20 {

    // Standard ERC20 information
    string  constant NAME = "Legolas Token";
    string  constant SYMBOL = "LGO";
    uint8   constant DECIMALS = 8;
    uint256 constant UNIT = 10**uint256(DECIMALS);

    // 5% for advisors
    uint256 constant ADVISORS_AMOUNT =   8750000 * UNIT;
    // 15% for founders
    uint256 constant FOUNDERS_AMOUNT =  26250000 * UNIT;
    // 60% sold in pre-sale
    uint256 constant HOLDERS_AMOUNT  = 105000000 * UNIT;
    // 20% reserve
    uint256 constant RESERVE_AMOUNT  =  35000000 * UNIT;
    // ADVISORS_AMOUNT + FOUNDERS_AMOUNT + HOLDERS_AMOUNT +RESERVE_AMOUNT
    uint256 constant INITIAL_AMOUNT  = 175000000 * UNIT;
    // 20% for holder bonus
    uint256 constant BONUS_AMOUNT    =  35000000 * UNIT;
    // amount already allocated to advisors
    uint256 public advisorsAllocatedAmount = 0;
    // amount already allocated to funders
    uint256 public foundersAllocatedAmount = 0;
    // amount already allocated to holders
    uint256 public holdersAllocatedAmount = 0;
    // list of all initial holders
    address[] initialHolders;
    // not distributed because the defaut value is false
    mapping (uint256 => bool) bonusNotDistributed;


    function Legolas() EIP20( // EIP20 constructor
        INITIAL_AMOUNT + BONUS_AMOUNT,
        NAME,
        DECIMALS,
        SYMBOL
    ) public {
        // initialize bonus date
        bonusNotDistributed[1534291200] = true; // Wed, 15 Aug 2018 00:00:00 +0000
        bonusNotDistributed[1550188800] = true; // Fri, 15 Feb 2019 00:00:00 +0000
        bonusNotDistributed[1565827200] = true; // Thu, 15 Aug 2019 00:00:00 +0000
        bonusNotDistributed[1581724800] = true; // Sat, 15 Feb 2020 00:00:00 +0000
    }

    /// @param _address The address of the recipient
    /// @param _amount Amount of the allocation
    /// @param _type Type of the recipient. 0 for advisor, 1 for founders.
    /// @return Whether the allocation was successful or not
    function allocate(address _address, uint256 _amount, uint8 _type) public onlyOwner returns (bool success) {
        // one allocations by address
        require(allocations[_address] == 0);

        if (_type == 0) { // advisor
            // check allocated amount
            require(advisorsAllocatedAmount + _amount <= ADVISORS_AMOUNT);
            // increase allocated amount
            advisorsAllocatedAmount += _amount;
            // mark address as advisor
            advisors[_address] = true;
        } else if (_type == 1) { // founder
            // check allocated amount
            require(foundersAllocatedAmount + _amount <= FOUNDERS_AMOUNT);
            // increase allocated amount
            foundersAllocatedAmount += _amount;
            // mark address as founder
            founders[_address] = true;
        } else {
            // check allocated amount
            require(holdersAllocatedAmount + _amount <= HOLDERS_AMOUNT + RESERVE_AMOUNT);
            // increase allocated amount
            holdersAllocatedAmount += _amount;
        }
        // set allocation
        allocations[_address] = _amount;
        // increase balance
        balances[_address] += _amount;
        // initialize bonus eligibility
        eligibleForBonus[_address] = true;
        // add to initial holders list
        initialHolders.push(_address);

        return true;
    }

    /// @notice Expensive. TODO: determine gas price for x holders
    /// @param _bonusDate Date of the bonus to distribute.
    /// @return Whether the bonus distribution was successful or not
    function distributeHolderBonus(uint256 _bonusDate) public returns (bool success) {
        /// bonus date must be past
        require(_bonusDate <= now);
        /// disrtibute bonus only once
        require(bonusNotDistributed[_bonusDate]);

        // calculate the total amount eligible for the bonus
        uint256 unspentAmount = 0;
        for (uint256 i = 0; i < initialHolders.length; i++) {
            if (eligibleForBonus[initialHolders[i]]) {
                unspentAmount += allocations[initialHolders[i]];
            }
        }

        // calculate the bonus for one holded LGO
        uint256 bonusByLgo = (BONUS_AMOUNT / 4) / unspentAmount;

        // distribute the bonus
        for (uint256 j = 0; j < initialHolders.length; j++) {
            if (eligibleForBonus[initialHolders[j]]) {
                balances[initialHolders[j]] += allocations[initialHolders[j]] * bonusByLgo;
            }
        }

        // set bonus as distributed
        bonusNotDistributed[_bonusDate] = false;
        return true;
    }
}
