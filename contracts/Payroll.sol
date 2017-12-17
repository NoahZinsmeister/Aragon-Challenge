pragma solidity ^0.4.18;

import "./zeppelin/contracts/ownership/Ownable.sol";

import "./Cooldown.sol";
import "./PayrollInterface.sol";


contract Payroll is Ownable, Cooldown, PayrollInterface {

    modifier onlyEmployee() {
        require(true);
        _;
    }

    /* OWNER ONLY */
    function addEmployee(
        address accountAddress,
        address[] allowedTokens,
        uint256 initialYearlyEURSalary
    )
        public
        onlyOwner
    {
        accountAddress;
        allowedTokens;
        initialYearlyEURSalary;
    }

    function setEmployeeSalary(uint256 employeeId, uint256 yearlyEURSalary) public onlyOwner {
        employeeId;
        yearlyEURSalary;
    }

    function removeEmployee(uint256 employeeId) public onlyOwner {
        employeeId;
    }

    function addFunds() public payable onlyOwner {

    }

    function scapeHatch() public onlyOwner {

    }

    function addTokenFunds() public{

    }


    function getEmployeeCount() public view returns (uint256) {

    }

    function getEmployee(uint256 employeeId) public view returns (address employee) {
        employeeId;
        return (0x0);
    }


    function calculatePayrollBurnrate() public view returns (uint256) {

    }

    function calculatePayrollRunway() public view returns (uint256) {

    }


    /* EMPLOYEE ONLY */
    function determineAllocation(address[] tokens, uint256[] distribution)
        public
        onlyEmployee
        onceEvery("determineAllocation", 1 years / 2)
    {
        tokens;
        distribution;
    }
    function payday() public onlyEmployee onceEvery("payday", 1 years / 12) {

    }


    /* ORACLE ONLY */
    function setExchangeRate(address token, uint256 EURExchangeRate) external;
}
