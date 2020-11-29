/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 *
 */
pragma solidity ^0.6.0;

import "../Library/Address.sol";

abstract contract AbstractInitializer {
    using Address for address;

    bool private _initialized;
    bool private _initializing;

    modifier initializer() {
        require(
            _initializing || !_initialized || !address(this).isContract(),
            "Initializer/Already Initialized"
        );

        bool isSurfaceCall = !_initializing;
        if (isSurfaceCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isSurfaceCall) {
            _initializing = false;
        }
    }
}
