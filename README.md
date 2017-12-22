# Status Coding Challenge: Software Engineer - Smart Contracts

### Solution Notes
While implementing this Payroll interface, I made several key design decisions, explained below. My intent was to make the code readable and clear.

The Payroll logic is found in [contracts/Payroll.sol](./contracts/Payroll.sol). I also implemented a [dummy EUR Token](./contracts/EURToken.sol) and an [oracle](./contracts/Oracle.sol) for testing purposes. Tests are in [tests/payroll.js](./tests/payroll.js).

* Employees are eligible to receive their salary at monthly-or-greater-increments. Employees must elect to receive their pay as a distribution over all ERC-20 token in the owner-determined token whitelist. The contract is _only_ able to pay out ERC20 tokens from this whitelist, with EUR being the default token.
* Notably, this means that employees _cannot_ elect to receive their salary in ether (I made this this restriction for the sake of simplicity). In the event that non-whitelisted tokens are sent to the contract (an event that would normally mark their demise), the owner may call `drainToken` to rescue the token balances. If anyone tries to transfer a non-whitelisted ERC223-compliant token to the contract, `tokenFallback` ensure that the transfer will fail. Again for the sake of simplicity, whitelisted tokens cannot be removed, nor can their addresses be changed.
* At first glance, `calculatePayrollRunway` seems to be intended to return the number of days before the contract will be unable to fulfill a possible employee `payday` request. THIS IS NOT THE CASE - currently, `calculatePayrollRunway` sums all white-listed token balances in EUR-converted units without accounting for the employee-decided distributions over tokens. So, while the number of days given by `calculatePayrollRunway` is accurate if that the contract's balances are appropriately distributed across tokens, it does not guarantee a time frame for which all `payday` requests will succeed. Keeping track of token distributions across all users would probably require a refactor. On a related note, you'll notice that I chose to use `transfer` rather than `approve` function to send tokens. This was because implementing `calculatePayrollRunway` would be much harder if we had to keep track of potentially withdrawable allowances by employees.
* The oracle has a hard-coded address (again, for simplicity), and it is assumed to update all whitelisted token balances via `setExchangeRate` at acceptably fine-grained intervals (ensuring that EUR token exchange rates are kept relatively up-to-date). In a real-world setting, one way to make this more practical would be for the relevant functions checking the difference between `now` and `rateLastUpdated` for each token and requesting an Oracle update via an Event.
* A note on the `EURExchangeRate`s sent by the oracle: Imagine two tokens, EUR and USD. Say the USD/EUR exchange rate is 3/1 (i.e. 3 USD trade for 1 EUR), but that EUR has 2 decimals while USD has 4. This means, of course, that 1 EUR is represented as 100 in the EUR contract, and 1 USD is represented as 10,000 in the USD contract. My code currently assumes that the oracle's `EURExchangeRate` value for USD/EUR is 3*10,000/100 = 300. This is a little fragile, because we could imagine that the decimals were flipped, in which case the `EURExchangeRate` would be 3/100, which we would be forced to store as 0 or 1 since our rate variable is a `uint`. In a real-world setting, the obvious way around this fragility would be to add a decimals-like precision multiplier (say, 1e18) to the rate, and simply adjust our calculations accordingly. For the sake of the exercise though, I have not done so.


I'd be happy to comment on any of the above in more detail, or discuss any additional features of my solution that I've omitted.
