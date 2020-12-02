// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.6.0;

import "./Library/SafeMath.sol";
import "./Library/Authority.sol";
import "./Library/Create2Maker.sol";
import "./Interface/IERC165.sol";
import "./Interface/IERC173.sol";
import "./Interface/IMint.sol";
import "./Interface/ITokenFactory.sol";
import "./Interface/Iinitialize.sol";

contract TokenFactory is Authority, IERC165, ITokenFactory {
    using SafeMath for uint256;

    struct Entity {
        bytes32 _key;
        TemplateInfo _value;
    }

    Entity[] entities;
    mapping(bytes32 => uint256) indexes;

    constructor() public {
        Authority.initialize(msg.sender);
    }

    function newTemplate(address template, uint256 price)
        external
        override
        onlyAuthority
        returns (bytes32 key)
    {
        require(
            _set(bytes32(uint256(template)), template, price),
            "TokenFactory/Already Exist"
        );
        key = bytes32(uint256(template));
        emit SetTemplate(bytes32(uint256(template)), template, price);
    }

    function updateTemplate(
        bytes32 key,
        address template,
        uint256 price
    ) external override onlyAuthority {
        require(
            !_set(key, template, price),
            "TokenFactory/Template is Not Exist"
        );
        emit SetTemplate(key, template, price);
    }

    function deleteTemplate(bytes32 key) external override onlyAuthority {
        require(_remove(key), "TokenFactory/Template is Not Exist");
        emit RemovedTemplate(key);
    }

    function newToken(
        bytes32 key,
        string memory version,
        string memory name,
        string memory symbol,
        uint8 decimals
    ) external payable override returns (address result) {
        result = _newToken(key, version, name, symbol, decimals);
        IERC173(result).transferOwnership(msg.sender);
    }

    function newTokenWithMint(
        bytes32 key,
        string memory version,
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 amount
    ) external payable override returns (address result) {
        result = _newToken(key, version, name, symbol, decimals);
        IMint(result).mintTo(amount, msg.sender);
        IERC173(result).transferOwnership(msg.sender);
    }

    function calculateNewTokenAddress(
        bytes32 key,
        string memory version,
        string memory name,
        string memory symbol,
        uint8 decimals
    ) external view override returns (address result) {
        TemplateInfo memory info = _get(key);

        bytes memory initializationCalldata =
            abi.encodeWithSelector(
                Iinitialize(info.template).initialize.selector,
                version,
                name,
                symbol,
                decimals
            );

        bytes memory initCode =
            abi.encodePacked(
                type(Create2Maker).creationCode,
                abi.encode(address(info.template), initializationCalldata)
            );

        (, result) = _getSaltAndTarget(initCode);
    }

    function supportsInterface(bytes4 interfaceID)
        external
        view
        override
        returns (bool)
    {
        return
            interfaceID == type(IERC165).interfaceId || // ERC165
            interfaceID == type(Iinitialize).interfaceId || // ERC2612
            interfaceID == type(ITokenFactory).interfaceId; // ITokenFactory
    }

    //@TODO: Template interface check.
    function _newToken(
        bytes32 key,
        string memory version,
        string memory name,
        string memory symbol,
        uint8 decimals
    ) internal returns (address result) {
        TemplateInfo memory info = _get(key);
        require(info.price == msg.value, "TokenFactory/Different deposited");

        bytes memory initializationCalldata =
            abi.encodeWithSelector(
                Iinitialize(info.template).initialize.selector,
                version,
                name,
                symbol,
                decimals
            );

        bytes memory create2Code =
            abi.encodePacked(
                type(Create2Maker).creationCode,
                abi.encode(address(info.template), initializationCalldata)
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

        payable(this.owner()).transfer(msg.value);
        emit GeneratedToken(msg.sender, result);
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

    function _set(
        bytes32 key,
        address template,
        uint256 price
    ) private returns (bool) {
        uint256 keyIndex = indexes[key];

        TemplateInfo memory tmp =
            TemplateInfo({template: template, price: price});

        if (keyIndex == 0) {
            entities.push(Entity({_key: key, _value: tmp}));
            indexes[key] = entities.length;
            return true;
        } else {
            entities[keyIndex.sub(1)]._value = tmp;
            return false;
        }
    }

    function _remove(bytes32 key) private returns (bool) {
        uint256 keyIndex = indexes[key];

        if (keyIndex != 0) {
            uint256 toDeleteIndex = keyIndex.sub(1);
            uint256 lastIndex = entities.length.sub(1);

            Entity storage lastEntity = entities[lastIndex];

            entities[toDeleteIndex] = lastEntity;
            indexes[lastEntity._key] = toDeleteIndex.add(1);

            entities.pop();

            delete indexes[key];
            return true;
        } else {
            return false;
        }
    }

    function _contains(bytes32 key) private view returns (bool) {
        return indexes[key] != 0;
    }

    function _length() private view returns (uint256) {
        return entities.length;
    }

    function _at(uint256 index)
        private
        view
        returns (bytes32, TemplateInfo memory)
    {
        require(entities.length > index, "index out of bounds");

        Entity storage entity = entities[index];
        return (entity._key, entity._value);
    }

    function _get(bytes32 key) private view returns (TemplateInfo memory) {
        return _get(key, "nonexistent key");
    }

    function _get(bytes32 key, string memory errorMessage)
        private
        view
        returns (TemplateInfo memory)
    {
        uint256 keyIndex = indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        return entities[keyIndex.sub(1)]._value; // All indexes are 1-based
    }
}
