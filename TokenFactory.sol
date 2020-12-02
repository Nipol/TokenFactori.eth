// Sources flattened with hardhat v2.0.4 https://hardhat.org

// File contracts/Library/SafeMath.sol

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.6.0;

library SafeMath {
    uint256 internal constant WAD = 1e18;
    uint256 internal constant RAY = 1e27;
    uint256 internal constant RAD = 1e45;

    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "Math/Add-Overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "Math/Sub-Overflow");
    }

    function sub(
        uint256 x,
        uint256 y,
        string memory message
    ) internal pure returns (uint256 z) {
        require((z = x - y) <= x, message);
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || ((z = x * y) / y) == x, "Math/Mul-Overflow");
    }

    function div(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y > 0, "Math/Div-Overflow");
        z = x / y;
    }

    function mod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y != 0, "Math/Mod-Overflow");
        z = x % y;
    }

    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }

    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    function toWAD(uint256 wad, uint256 decimal)
        internal
        pure
        returns (uint256 z)
    {
        require(decimal < 18, "Math/Too-high-decimal");
        z = mul(wad, 10**(18 - decimal));
    }
}


// File contracts/Interface/IERC173.sol

pragma solidity ^0.6.0;

/// @title ERC-173 Contract Ownership Standard
/// @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-173.md
///  Note: the ERC-165 identifier for this interface is 0x7f5828d0
/* is ERC165 */
interface IERC173 {
    /// @dev This emits when ownership of a contract changes.
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /// @notice Get the address of the owner
    /// @return The address of the owner.
    function owner() external view returns (address);

    /// @notice Set the address of the new owner of the contract
    /// @param newOwner The address of the new owner of the contract
    function transferOwnership(address newOwner) external;
}


// File contracts/Library/Authority.sol

pragma solidity ^0.6.0;

contract Authority is IERC173 {
    address private _owner;

    modifier onlyAuthority() {
        require(_owner == msg.sender, "Authority/Not-Authorized");
        _;
    }

    function initialize(address newOwner) internal {
        _owner = newOwner;
        emit OwnershipTransferred(address(0), newOwner);
    }

    function owner() external view override returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner)
        external
        override
        onlyAuthority
    {
        _owner = newOwner;
        emit OwnershipTransferred(msg.sender, newOwner);
    }
}


// File contracts/Library/Create2Maker.sol

pragma solidity ^0.6.0;

contract Create2Maker {
    constructor(address template, bytes memory initializationCalldata)
        public
        payable
    {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = template.delegatecall(initializationCalldata);
        if (!success) {
            // pass along failure message from delegatecall and revert.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        // place eip-1167 runtime code in memory.
        bytes memory runtimeCode =
            abi.encodePacked(
                bytes10(0x363d3d373d3d3d363d73),
                template,
                bytes15(0x5af43d82803e903d91602b57fd5bf3)
            );

        // return eip-1167 code to write it to spawned contract runtime.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            return(add(0x20, runtimeCode), 45) // eip-1167 runtime code, length
        }
    }
}


// File contracts/Interface/IERC165.sol

pragma solidity ^0.6.0;

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}


// File contracts/Interface/IMint.sol

pragma solidity ^0.6.0;

interface IMint {
    function mint(uint256 value) external returns (bool);

    function mintTo(uint256 value, address to) external returns (bool);
}


// File contracts/Interface/ITokenFactory.sol

pragma solidity ^0.6.0;

interface ITokenFactory {
    struct TemplateInfo {
        address template;
        uint256 price;
    }

    event SetTemplate(
        bytes32 indexed key,
        address indexed template,
        uint256 indexed price
    );

    event RemovedTemplate(bytes32 indexed key);

    event GeneratedToken(address owner, address token);

    function newTemplate(address template, uint256 price)
        external
        returns (bytes32 key);

    function updateTemplate(
        bytes32 key,
        address template,
        uint256 price
    ) external;

    function deleteTemplate(bytes32 key) external;

    function newToken(
        bytes32 key,
        string memory version,
        string memory name,
        string memory symbol,
        uint8 decimals
    ) external payable returns (address result);

    function newTokenWithMint(
        bytes32 key,
        string memory version,
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 amount
    ) external payable returns (address result);

    function calculateNewTokenAddress(
        bytes32 key,
        string memory version,
        string memory name,
        string memory symbol,
        uint8 decimals
    ) external view returns (address result);
}


// File contracts/Interface/Iinitialize.sol

pragma solidity ^0.6.0;

interface Iinitialize {
    function initialize(
        string calldata contractVersion,
        string calldata tokenName,
        string calldata tokenSymbol,
        uint8 tokenDecimals
    ) external;
}


// File contracts/TokenFactory.sol

pragma solidity ^0.6.0;








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
