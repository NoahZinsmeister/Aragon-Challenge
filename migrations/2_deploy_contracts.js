var Oracle = artifacts.require("./Oracle.sol");
var EURToken = artifacts.require("./EURToken.sol");
var Payroll = artifacts.require("./Payroll.sol");

module.exports = function(deployer) {
    deployer.deploy(Oracle).then(function() {
        return deployer.deploy(EURToken, 10).then(function() {
            return deployer.deploy(Payroll, Oracle.address, EURToken.address);
        });
    });
};
