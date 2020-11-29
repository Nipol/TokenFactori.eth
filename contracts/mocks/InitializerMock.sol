// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.6.0;

import "../abstract/Initializer.sol";

contract InitializerMock is AbstractInitializer {
    function initialize() external initializer returns (bool) {
        return true;
    }
}
