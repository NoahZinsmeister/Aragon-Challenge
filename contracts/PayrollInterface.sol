pragma solidity ^0.4.18;

// For the sake of simplicity lets assume EUR is a ERC20 token
// Also lets assume we can 100% trust the exchange rate oracle
contract PayrollInterface {
    //// ORACLE ONLY ////
    // uses token decimals
    function setExchangeRate(address token, uint256 EURExchangeRate) external;

    //// OWNER ONLY ////
    function addEmployee(
        address accountAddress,
        address[] allowedTokens,
        uint256[] tokenDistribution,
        uint256 initialYearlyEURSalary) public returns(uint256 employeeId);
    function setEmployeeSalary(uint256 employeeId, uint256 yearlyEURSalary) public;
    function removeEmployee(uint256 employeeId) public;
    function lock() public;
    function unlock() public;
    function getEmployeeCount() public view returns (uint256);
    function getEmployee(uint256 employeeId) public view returns (
        address employeeAddress,
        address[] allowedTokens,
        uint256[] tokenDistribution,
        uint256 yearlyEURSalary,
        uint256 lastPayday,
        uint256 lastAllocation
    );
    // Monthly token amount spent on salaries denominated in EUR
    function calculatePayrollBurnrate() public view returns (uint256);
    // Days until the contract can run out of funds (assumes 30 days/month)
    function calculatePayrollRunway() public view returns (uint256);

    //// EMPLOYEE ONLY ////
    // only callable once every 6 months
    function determineAllocation(address[] tokens, uint256[] distribution) public;
    // only callable once a month
    function payday() public;
}
