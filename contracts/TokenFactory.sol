// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.6.0;

import "./Interface/Iinitialize.sol";
import "./Library/Create2Maker.sol";

contract TokenFactory {
    Iinitialize public token;

    constructor(address tokenTemplate) public {
        token = Iinitialize(tokenTemplate);
    }

    function newToken(
        address owner,
        string memory version,
        string memory name,
        string memory symbol,
        uint8 decimals
    ) public returns (address result) {
        bytes memory initializationCalldata = abi.encodeWithSelector(
            token.initialize.selector,
            owner,
            version,
            name,
            symbol,
            decimals
        );

        bytes memory create2Code = abi.encodePacked(
            type(Create2Maker).creationCode,
            abi.encode(address(token), initializationCalldata)
        );

        (bytes32 salt, ) = _getSaltAndTarget(create2Code);

        // solhint-disable-next-line no-inline-assembly
        assembly {
            let encoded_data := add(0x20, create2Code) // load initialization code.
            let encoded_size := mload(create2Code) // load the init code's length.
            result := create2(
                // call `CREATE2` w/ 4 arguments.
                callvalue(), // forward any supplied endowment.
                encoded_data, // pass in initialization code.
                encoded_size, // pass in init code's length.
                salt // pass in the salt value.
            )

            // pass along failure message from failed contract deployment and revert.
            if iszero(result) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    function calculateNewTokenAddress(
        address contractOwner,
        string memory version,
        string memory name,
        string memory symbol,
        uint8 decimals
    ) public view returns (address result) {
        bytes memory initializationCalldata = abi.encodeWithSelector(
            token.initialize.selector,
            contractOwner,
            version,
            name,
            symbol,
            decimals
        );

        bytes memory initCode = abi.encodePacked(
            type(Create2Maker).creationCode,
            abi.encode(address(token), initializationCalldata)
        );

        (, result) = _getSaltAndTarget(initCode);
    }

    function _getSaltAndTarget(bytes memory initCode)
        private
        view
        returns (bytes32 salt, address target)
    {
        // get the keccak256 hash of the init code for address derivation.
        bytes32 initCodeHash = keccak256(initCode);

        // set the initial nonce to be provided when constructing the salt.
        uint256 nonce = 0;

        // declare variable for code size of derived address.
        bool exist;

        while (true) {
            // derive `CREATE2` salt using `msg.sender` and nonce.
            salt = keccak256(abi.encodePacked(msg.sender, nonce));

            target = address( // derive the target deployment address.
                uint160( // downcast to match the address type.
                    uint256( // cast to uint to truncate upper digits.
                        keccak256( // compute CREATE2 hash using 4 inputs.
                            abi.encodePacked( // pack all inputs to the hash together.
                                bytes1(0xff), // pass in the control character.
                                address(this), // pass in the address of this contract.
                                salt, // pass in the salt from above.
                                initCodeHash // pass in hash of contract creation code.
                            )
                        )
                    )
                )
            );

            // determine if a contract is already deployed to the target address.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                exist := gt(extcodesize(target), 0)
            }

            // exit the loop if no contract is deployed to the target address.
            if (!exist) {
                break;
            }

            // otherwise, increment the nonce and derive a new salt.
            nonce++;
        }
    }
}
