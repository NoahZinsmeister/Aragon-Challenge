var Oracle = artifacts.require("./Oracle.sol");
var EURToken = artifacts.require("./EURToken.sol");
var Payroll = artifacts.require("./Payroll.sol");

contract('Payroll', function(accounts) {
    it("should initialize correctly", async function () {
        let payrollInstance = await Payroll.deployed();
        let employeeCount = await payrollInstance.getEmployeeCount.call();
        assert.equal(employeeCount, 0, "> 0 users at the start");
    });
});
