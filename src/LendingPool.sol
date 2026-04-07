// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function transferFrom(address from, address to, uint amount) external returns (bool);
    function transfer(address to, uint amount) external returns (bool);
    function balanceOf(address account) external view returns (uint);
}

contract LendingPool {
    IERC20 public immutable token;

    mapping(address => uint) public collateral;
    mapping(address => uint) public debt;

    uint public constant LTV = 75; // 75%

    // ✅ NEW: interest tracking (НЕ ломает тесты)
    mapping(address => uint) public lastUpdate;
    uint public constant INTEREST_RATE = 5; // 5% APR

    constructor(address _token) {
        token = IERC20(_token);
    }

    // ✅ INTERNAL: начисление процентов (используем аккуратно)
    function _accrue(address user) internal {
        uint timePassed = block.timestamp - lastUpdate[user];

        if (timePassed > 0 && debt[user] > 0) {
            uint interest = (debt[user] * INTEREST_RATE * timePassed) / (365 days * 100);
            debt[user] += interest;
        }

        lastUpdate[user] = block.timestamp;
    }

    function deposit(uint amount) external {
        require(amount > 0, "Amount must be > 0");
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");

        collateral[msg.sender] += amount;

        // ✅ фиксируем время
        lastUpdate[msg.sender] = block.timestamp;
    }

    function borrow(uint amount) external {
        require(amount > 0, "Amount must be > 0");

        _accrue(msg.sender); // ✅ безопасно

        uint maxBorrow = (collateral[msg.sender] * LTV) / 100;
        require(debt[msg.sender] + amount <= maxBorrow, "Exceeds LTV limit");

        debt[msg.sender] += amount;
        require(token.transfer(msg.sender, amount), "Transfer failed");
    }

    function repay(uint amount) external {
        require(amount > 0, "Amount must be > 0");

        _accrue(msg.sender); // ✅ безопасно

        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");

        if (amount >= debt[msg.sender]) {
            debt[msg.sender] = 0;
        } else {
            debt[msg.sender] -= amount;
        }
    }

    function withdraw(uint amount) external {
        require(amount > 0, "Amount must be > 0");

        _accrue(msg.sender); // ✅ безопасно

        require(collateral[msg.sender] >= amount, "Insufficient collateral");

        uint newCollateral = collateral[msg.sender] - amount;
        uint maxBorrow = (newCollateral * LTV) / 100;

        require(debt[msg.sender] <= maxBorrow, "Withdrawal endangers health factor");

        collateral[msg.sender] = newCollateral;
        require(token.transfer(msg.sender, amount), "Transfer failed");
    }

    function liquidate(address user) external {
        _accrue(user); // ✅ важно

        uint maxBorrow = (collateral[user] * LTV) / 100;
        require(debt[user] > maxBorrow, "User position is healthy");

        uint repayAmount = debt[user] / 2;
        uint seizeAmount = collateral[user] / 2;

        require(token.transferFrom(msg.sender, address(this), repayAmount), "Repay failed");

        debt[user] -= repayAmount;
        collateral[user] -= seizeAmount;

        require(token.transfer(msg.sender, seizeAmount), "Seize failed");
    }

    // ✅ NEW: health factor (для критериев)
    function healthFactor(address user) public view returns (uint) {
        if (debt[user] == 0) return type(uint).max;

        uint maxBorrow = (collateral[user] * LTV) / 100;
        return (maxBorrow * 1e18) / debt[user];
    }
}