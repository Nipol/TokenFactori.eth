// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.6.0;

import "../abstract/Initializer.sol";

contract InitializerConstructorMock is AbstractInitializer {
    constructor() public initializer {}
}
