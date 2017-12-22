pragma solidity ^0.4.18;

import "./zeppelin/ownership/Ownable.sol";
import "./zeppelin/math/SafeMath.sol";
import "./zeppelin/token/ERC20Basic.sol";

import "./PayrollInterface.sol";


contract Payroll is Ownable, PayrollInterface {

    using SafeMath for uint256;

    //// CONTRACT VARIABLES ////
    // miscellaneous contract variables initialized in the constructor
    address oracleAddress;
    enum states { Locked, Unlocked }
    states contractState;

    // token logic
    struct Token {
        address tokenAddress;
        uint256 EURExchangeRate;
        uint256 rateLastUpdated;
    }
    mapping(address => Token) tokenRegister;
    address[] tokenWhitelist;

    // employee logic
    struct Employee {
        uint256 employeeId;
        address employeeAddress;
        address[] allowedTokens;
        uint256[] tokenDistribution;
        uint256 yearlyEURSalary;
        uint256 lastPayday;
        uint256 lastAllocation;
    }
    mapping(address => uint256) employeeIds;
    mapping(uint256 => Employee) employeeRegister;
    uint256 nextEmployeeId;
    uint256 totalYearlyEURSalary;
    uint256 employeeCount;

    //// MODIFIERS ////
    modifier onlyOracle() {
        require(msg.sender == oracleAddress);
        _;
    }

    modifier unlocked() {
        require(contractState == states.Unlocked);
        _;
    }

    modifier isEmployee(address challenge, bool desired) {
        require((employeeIds[challenge] > 0) == desired);
        _;
    }

    //// CONSTRUCTOR ////
    function Payroll(address _oracleAddress, address _EURAddress) public {
        // employee ids begin at 1
        nextEmployeeId = 1;
        // hardcode the oracle address
        oracleAddress = _oracleAddress;
        // add EUR Token Support
        addTokenToWhiteList(_EURAddress);
        // off to the races
        contractState = states.Unlocked;
    }

    //// FALLBACK ////
    function () public { revert(); }

    //// EXTERNAL - ORACLE ONLY ////
    function setExchangeRate(address token, uint256 EURExchangeRate) external onlyOracle {
        require(supportsToken(token));
        Token storage _token = tokenRegister[token];
        _token.EURExchangeRate = EURExchangeRate;
        _token.rateLastUpdated = now;
    }

    //// PUBLIC - OWNER ONLY ////
    function addEmployee(
        address accountAddress,
        address[] allowedTokens,
        uint256[] tokenDistribution,
        uint256 initialYearlyEURSalary
    )
        public
        onlyOwner
        isEmployee(accountAddress, false)
        returns (uint256 employeeId)
    {
        employeeCount++;
        totalYearlyEURSalary = totalYearlyEURSalary.add(initialYearlyEURSalary);

        employeeId = nextEmployeeId++;
        employeeIds[accountAddress] = employeeId;
        employeeRegister[employeeId] = Employee(
            employeeId,
            accountAddress,
            allowedTokens,
            tokenDistribution,
            initialYearlyEURSalary,
            now,
            0
        );

        _determineAllocation(employeeId, allowedTokens, tokenDistribution);

        return employeeId;
    }

    function setEmployeeSalary(uint256 employeeId, uint256 yearlyEURSalary)
        public
        onlyOwner
        isEmployee(employeeRegister[employeeId].employeeAddress, true)
    {
        Employee storage employee = employeeRegister[employeeId];

        totalYearlyEURSalary =
            totalYearlyEURSalary.sub(employee.yearlyEURSalary).add(yearlyEURSalary);
        employee.yearlyEURSalary = yearlyEURSalary;
    }

    function removeEmployee(uint256 employeeId)
        public
        onlyOwner
        isEmployee(employeeRegister[employeeId].employeeAddress, true)
    {
        // since we're deleteing this entry, it's clearer to work with a temporary copy in memory
        Employee memory employee = employeeRegister[employeeId];

        employeeCount--;
        totalYearlyEURSalary = totalYearlyEURSalary.sub(employee.yearlyEURSalary);

        delete employeeIds[employee.employeeAddress];
        delete employeeRegister[employeeId];
    }

    function addTokenToWhiteList(address token) public onlyOwner {
        require(!supportsToken(token));
        tokenWhitelist.push(token);
        tokenRegister[token] = Token(token, 0, 0);
    }

    function lock() public onlyOwner {
        contractState = states.Locked;

        // try to send all tokens to the owner
        for (uint256 i = 0; i < tokenWhitelist.length; i++) {
            ERC20Basic token = ERC20Basic(tokenWhitelist[i]);
            token.transfer(owner, token.balanceOf(this));
        }
    }

    function unlock() public onlyOwner {
        contractState = states.Unlocked;
    }

    //// PUBLIC - TOKEN INTERACTIONS ////
    // deal with erc223-compliant tokens (reject if not in whitelist) - Dexaran implementation
    function tokenFallback(address _from, uint, bytes) public {
        require(supportsToken(_from));
    }

    // safety valve ensuring that no token can ever be "stuck" in the contract
    function drainToken(address tokenAddress) public onlyOwner {
        ERC20Basic token = ERC20Basic(tokenAddress);
        token.transfer(owner, token.balanceOf(this));
    }
    // returns true if token is whitelisted
    function supportsToken(address token) public view returns (bool) {
        return(tokenRegister[token].tokenAddress != 0x0);
    }


    //// PUBLIC - USEFUL VIEW FUNCTIONS ////
    function getEmployeeCount() public view returns (uint256) { return employeeCount; }

    function getEmployee(uint256 employeeId)
        public
        view
        returns (
            address employeeAddress,
            address[] allowedTokens,
            uint256[] tokenDistribution,
            uint256 yearlyEURSalary,
            uint256 lastPayday,
            uint256 lastAllocation
        )
    {
        Employee storage _employee = employeeRegister[employeeId];

        return (
            _employee.employeeAddress,
            _employee.allowedTokens,
            _employee.tokenDistribution,
            _employee.yearlyEURSalary,
            _employee.lastPayday,
            _employee.lastAllocation
        );
    }

    function getWhitelist() public view returns (address[] whitelist) { return tokenWhitelist; }

    // projected monthly token ouflows, denominated in EUR
    function calculatePayrollBurnrate() public view returns (uint256) {
        return totalYearlyEURSalary.div(12);
    }

    // days before the contract will be broke
    // WARNING: calculations are based on EUR-converted balances...
    // ...the contract could run out of any whitelisted token at any time
    function calculatePayrollRunway() public view returns (uint256) {
        uint256 EURBalance;
        for (uint256 i = 0; i < tokenWhitelist.length; i++) {
            Token storage token = tokenRegister[tokenWhitelist[i]];
            uint256 tokenBalanceInEUR =
                ERC20Basic(token.tokenAddress).balanceOf(this).div(token.EURExchangeRate);
            EURBalance = EURBalance.add(tokenBalanceInEUR);
        }
        return EURBalance.div(totalYearlyEURSalary.div(365));
    }

    //// PUBLIC - EMPLOYEE ONLY ////
    function determineAllocation(address[] tokens, uint256[] distribution)
        public
        unlocked
        isEmployee(msg.sender, true)
    {
        _determineAllocation(employeeIds[msg.sender], tokens, distribution);
    }

    function payday() public unlocked isEmployee(msg.sender, true) {
        Employee storage employee = employeeRegister[employeeIds[msg.sender]];

        // ensure the employee hasn't called this function for at least 1 month
        require(now > (employee.lastAllocation + (1 years / 12)));

        // calculate the amount of EUR the employee is owed based on seconds since last payday
        uint256 EUROwed  = (now - employee.lastPayday).mul(employee.yearlyEURSalary).div(1 years);

        // for each token the employee accepts, send the appropriate share
        for (uint256 i = 0; i < employee.allowedTokens.length; i++) {
            Token storage token = tokenRegister[employee.allowedTokens[i]];
            // compute the amount of the current token owed to the employee
            uint256 tokenOwed = EUROwed.mul(employee.tokenDistribution[i]).div(100).mul(token.EURExchangeRate);
            require(ERC20Basic(token.tokenAddress).transfer(msg.sender, tokenOwed));
        }
    }

    //// INTERNAL ////
    // interal allocation determination, allows an employee-only version and version in addEmployee
    function _determineAllocation(uint256 employeeId, address[] tokens, uint256[] distribution)
        internal
    {
        Employee storage employee = employeeRegister[employeeId];

        // ensure the employee hasn't called this function for at least 6 months
        require(now > (employee.lastAllocation + (1 years / 2)));

        // ensure the distribution is valid
        require(tokens.length == distribution.length);
        checkDistribution(distribution);
        for (uint256 i = 0; i < tokens.length; i++) {
            require(supportsToken(tokens[i]));
        }

        // update the distribution and reset the cooldown
        employee.allowedTokens = tokens;
        employee.tokenDistribution = distribution;
        employee.lastAllocation = now;
    }
    // ensures that the sum of the passed uint array is 100 i.e. a valid distribution
    function checkDistribution(uint256[] distribution) internal pure {
        uint256 distributionSum;
        for (uint256 i = 0; i < distribution.length; i++) {
            distributionSum = distributionSum.add(distribution[i]);
        }
        require(distributionSum == 100);
    }
}
