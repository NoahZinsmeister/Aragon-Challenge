pragma solidity ^0.4.18;

// allows functions to be called only if at least x seconds have elapsed since a previous call
// warning: relies on now aka block.timestamp which can be manipulated by miners to an extent

contract Cooldown {
    // use string as cooldown keys because e.g. msg.sig can change for external function calls
    mapping(string => uint256) lastCalled;

    // throws if the identifier is still is in the cooldown phase
    modifier onceEvery(string identifier, uint256 cooldown) {
        require(now >= lastCalled[identifier] + cooldown);
        _;
        lastCalled[identifier] = now;
    }
}
