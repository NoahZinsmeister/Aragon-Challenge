pragma solidity ^0.4.18;

// For the sake of simplicity lets assume EUR is a ERC20 token
// Also lets assume we can 100% trust the exchange rate oracle
contract PayrollInterface {
    //// ORACLE ONLY ////
    // uses token decimals
    function setExchangeRate(address token, uint256 EURExchangeRate) external;

    //// PUBLIC - OWNER ONLY ////
    function addEmployee(
        address accountAddress,
        address[] allowedTokens,
        uint256[] tokenDistribution,
        uint256 initialYearlyEURSalary) public returns(uint256 employeeId);
    function setEmployeeSalary(uint256 employeeId, uint256 yearlyEURSalary) public;
    function removeEmployee(uint256 employeeId) public;
    function addTokenToWhiteList(address token) public;
    function lock() public;
    function unlock() public;

    //// PUBLIC - TOKEN INTERACTIONS ////
    function tokenFallback(address _from, uint, bytes) public;
    function drainToken(address tokenAddress) public;
    function supportsToken(address token) public view returns (bool);

    //// PUBLIC - USEFUL VIEW FUNCTIONS ////
    function getEmployeeCount() public view returns (uint256);
    function getEmployee(uint256 employeeId) public view returns (
        address employeeAddress,
        address[] allowedTokens,
        uint256[] tokenDistribution,
        uint256 yearlyEURSalary,
        uint256 lastPayday,
        uint256 lastAllocation
    );
    function getWhitelist() public view returns (address[]);
    // Monthly token amount spent on salaries denominated in EUR
    function calculatePayrollBurnrate() public view returns (uint256);
    // Days until the contract can run out of funds (assumes 30 days/month)
    function calculatePayrollRunway() public view returns (uint256);

    //// PUBLIC - EMPLOYEE ONLY ////
    // only callable once every 6 months
    function determineAllocation(address[] tokens, uint256[] distribution) public;
    // only callable once a month
    function payday() public;
}
