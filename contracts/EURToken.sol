pragma solidity ^0.4.18;


import "./zeppelin/token/BasicToken.sol";


/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract EURToken is BasicToken {
    uint8 public decimals = 18;
    uint256 public totalSupply;

    function EURToken(uint256 initialSupply) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);
        balances[msg.sender] = totalSupply;
    }
}
