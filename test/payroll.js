var Oracle = artifacts.require("./Oracle.sol");
var EURToken = artifacts.require("./EURToken.sol");
var Payroll = artifacts.require("./Payroll.sol");

contract('Payroll', function(accounts) {
    var payrollInstance;

    it("should initialize correctly", async function () {
        payrollInstance = await Payroll.deployed();
        payrollInstance.getEmployeeCount.call().then(function(count) {
            assert.equal(count, 0, "> 0 users upon initialization");
        });
    });

    // we need access to a persistent EUR token contract for the following tests
    contract('EURToken', function(accounts) {
        var EURTokenInstance;
        var transferAmount = 12;

        it("should accept token funds", async function () {
            EURTokenInstance = await EURToken.new([100]);

            // transfer 12 EUR to the payroll contract
            return EURTokenInstance.transfer(payrollInstance.address, transferAmount)
              .then(function() {
                return EURTokenInstance.balanceOf(payrollInstance.address);
            }).then(function(payrollBalance) {
                assert.equal(
                    payrollBalance.toNumber(),
                    transferAmount,
                    "token transfer failed");
            });
        });

        it("should retain token funds", async function () {
            // check that tokens sent in last test are retained
            return EURTokenInstance.balanceOf(payrollInstance.address).then(function(balance) {
                assert.equal(
                    balance.toNumber(),
                    transferAmount,
                    "tokens were lost");
            });
        });
    });
});
