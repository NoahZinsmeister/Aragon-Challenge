pragma solidity ^0.4.18;

// For the sake of simplicity lets assume EUR is a ERC20 token
// Also lets assume we can 100% trust the exchange rate oracle
contract PayrollInterface {
    /* OWNER ONLY */
    function addEmployee(address accountAddress, address[] allowedTokens, uint256 initialYearlyEURSalary) public;
    function setEmployeeSalary(uint256 employeeId, uint256 yearlyEURSalary) public;
    function removeEmployee(uint256 employeeId) public;

    function addFunds() public payable;
    function scapeHatch() public;
    // function addTokenFunds()? // Use approveAndCall or ERC223 tokenFallback

    function getEmployeeCount() public view returns (uint256);
    function getEmployee(uint256 employeeId) public view returns (address employee); // Return all important info too

    function calculatePayrollBurnrate() public view returns (uint256); // Monthly EUR amount spent in salaries
    function calculatePayrollRunway() public view returns (uint256); // Days until the contract can run out of funds

    /* EMPLOYEE ONLY */
    function determineAllocation(address[] tokens, uint256[] distribution) public; // only callable once every 6 months
    function payday() public; // only callable once a month

    /* ORACLE ONLY */
    function setExchangeRate(address token, uint256 EURExchangeRate) external; // uses decimals from token
}
