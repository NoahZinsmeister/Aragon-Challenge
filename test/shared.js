var Oracle = artifacts.require("./Oracle.sol");
var EURToken = artifacts.require("./EURToken.sol");

// courtesy of mattdlockyer
async function loadSharedContext(accounts) {
    const EURTokenInstance = await EURToken.new([1000]);
    const oracleInstance = await Oracle.deployed();

    it("EURToken should be deployed", () => {
        assert(EURTokenInstance !== undefined, "EURToken is deployed");
    });
    it("Oracle should be deployed", () => {
        assert(oracleInstance !== undefined, "Oracle is deployed");
    });

    return { EURTokenInstance: EURTokenInstance, oracleInstance: oracleInstance };
}

exports.run = loadSharedContext;
//contract('Shared', loadSharedContext);
