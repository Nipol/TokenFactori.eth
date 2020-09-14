// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.6.0;

import "../Library/Address.sol";

contract AddressChecker {
    using Address for address;

    function check(address target) external view returns (bool result) {
        result = target.isContract();
    }
}
