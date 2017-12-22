var Payroll = artifacts.require("./Payroll.sol");

const shared = require('./shared.js');

const timeTravel = function (time) {
    return new Promise((resolve, reject) => {
        web3.currentProvider.sendAsync({
            jsonrpc: "2.0",
            method: "evm_increaseTime",
            params: [time], // 86400 is num seconds in day
            id: new Date().getTime()
        }, (err, result) => {
            if (err) { return reject(err); }
            return resolve(result);
        });
    });
};

contract('Payroll', function(accounts) {
    let EURTokenInstance;
    let oracleInstance;
    let payrollInstance;

    it("the shared context should be loaded", async function () {
        context = await shared.run(accounts);
        EURTokenInstance = context.EURTokenInstance;
        oracleInstance = context.oracleInstance;
        assert(EURTokenInstance !== undefined, 'has EURTokenInstance');
        assert(oracleInstance !== undefined, 'has oracleInstance');
    });

    it("Payroll initialized", async function () {
        payrollInstance = await Payroll.new(oracleInstance.address, EURTokenInstance.address);
    });

    it("Payroll was given appropriate constructor arguments", async function () {
        payrollInstance.getWhitelist().then(function (list) {
            assert.deepEqual(list, [EURTokenInstance.address], "poorly specified constructor args");
        });
    });

    it("should have 0 users at the start", async function () {
        payrollInstance.getEmployeeCount.call().then(function(count) {
            assert.equal(count, 0, "> 0 users upon initialization");
        });
    });

    it("should receive EUR", async function () {
        let transferAmount = 300000;

        // transfer EUR to the payroll contract
        let result = await EURTokenInstance.transfer(payrollInstance.address, transferAmount)
        assert.isOk(result.receipt.status, "token transfer failed");
        let balance = await EURTokenInstance.balanceOf.call(payrollInstance.address);
        assert.equal(balance, transferAmount, "token not received");
    });

    let yearlyEURSalary = 200000;
    it("can add first employee", async function () {
        let result = await payrollInstance.addEmployee(
            accounts[1],
            [EURTokenInstance.address],
            [100],
            yearlyEURSalary)
        assert.isOk(result.receipt.status, "adding employee failed");
        let employeeInformation = await payrollInstance.getEmployee.call(1);
        assert.equal(employeeInformation[0], accounts[1], "bad employeeAddress");
        assert.deepEqual(employeeInformation[1], [EURTokenInstance.address], "bad allowedTokens");
        assert.deepEqual(employeeInformation[2].map(x => x.toNumber()), [100], "bad tokenDistribution");
        assert.equal(employeeInformation[3], yearlyEURSalary, "bad yearlyEURSalary");
        assert.isAbove(employeeInformation[4], 0, "bad lastPayday");
        assert.isAbove(employeeInformation[4], 0, "bad lastAllocation");

        let count = await payrollInstance.getEmployeeCount.call();
        assert.equal(count, 1, "employee count not updated appropriately");
    });

    it("payday should be on cooldown now...", async function () {
        try {
            await payrollInstance.payday({from: accounts[1]});
        } catch(error) {
            return true
        }
        throw new Error("payday was callable")
    });

    it("...as should determineAllocation", async function () {
        try {
            await payrollInstance.determineAllocation.call(
                [EURTokenInstance.address],
                [100],
                { from: accounts[1] });
        } catch(error) {
            return true
        }
        throw new Error("determineAllocation was callable")
    });

    it("payday should be functional after e.g. a year...", async function () {
        await timeTravel(60*60*24*365);
        // update the exchange rate
        await oracleInstance.sendExchangeRateUpdate(
            payrollInstance.address,
            EURTokenInstance.address,
            1);
        await payrollInstance.payday({from: accounts[1]});
        let tokenBalance = (await EURTokenInstance.balanceOf.call(accounts[1])).toNumber();
        assert.equal(tokenBalance, yearlyEURSalary, "incorrect payment");
    });

    it("...as should determineAllocation", async function () {
        let result = await payrollInstance.determineAllocation(
            [EURTokenInstance.address],
            [100],
            { from: accounts[1] });
        assert.isOk(result.receipt.status, "determineAllocation could not be called");
    });

    it("check calculatePayrollBurnrate", async function () {
        let rate = (await payrollInstance.calculatePayrollBurnrate()).toNumber();
        assert.closeTo(rate, yearlyEURSalary/12, 1, "incorrect burnrate calculation")
    });

    it("check calculatePayrollRunway", async function () {
        let runway = (await payrollInstance.calculatePayrollRunway()).toNumber();
        assert.closeTo(runway, 365/2, 1, "incorrect runway calculation")
    });

    it("remove employee", async function () {
        await payrollInstance.removeEmployee(1);
        let count = await payrollInstance.getEmployeeCount.call();
        assert.equal(count, 0, "employee count not updated appropriately");
    });
});
