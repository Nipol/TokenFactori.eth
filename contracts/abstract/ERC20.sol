/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 *
 */
pragma solidity ^0.6.0;

abstract contract AbstractERC20 {
    function _approve(
        address owner,
        address spender,
        uint256 value
    ) internal virtual;

    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal virtual;
}
