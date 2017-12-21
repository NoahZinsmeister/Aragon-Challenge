pragma solidity ^0.4.18;

contract OracleReceiver {
    function setExchangeRate(address token, uint256 EURExchangeRate) external;
}

contract Oracle {
    function sendExchangeRateUpdate(address to, address token, uint256 EURExchangeRate) public {
        OracleReceiver(to).setExchangeRate(token, EURExchangeRate);
    }
}
