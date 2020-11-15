/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 *
 */
pragma solidity ^0.6.0;

import "./Library/SafeMath.sol";
import "./Library/Address.sol";
import "./Library/Authority.sol";
import "./Interface/IERC20.sol";
import "./Interface/IERC165.sol";
import "./Interface/IERC173.sol";
import "./Interface/IERC2612.sol";
import "./Interface/Iinitialize.sol";
import {AbstractERC2612} from "./abstract/ERC2612.sol";

contract StandardToken is
    Authority,
    AbstractERC2612,
    Iinitialize,
    IERC2612,
    IERC165,
    IERC20
{
    using SafeMath for uint256;
    using Address for address;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    function initialize(
        string calldata contractVersion,
        string calldata tokenName,
        string calldata tokenSymbol,
        uint8 tokenDecimals
    ) external override {
        Authority.initialize(msg.sender);
        _initDomainSeparator(contractVersion, tokenName);

        _name = tokenName;
        _symbol = tokenSymbol;
        _decimals = tokenDecimals;
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function approve(address spender, uint256 value)
        external
        override
        returns (bool)
    {
        _approve(msg.sender, spender, value);
        return true;
    }

    function balanceOf(address target)
        external
        view
        override
        returns (uint256)
    {
        return _balances[target];
    }

    function allowance(address owner, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function transfer(address to, uint256 value)
        external
        override
        returns (bool)
    {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override returns (bool) {
        _allowances[from][msg.sender] = _allowances[from][msg.sender].sub(
            value,
            "ERC20/Not-Enough-Allowance"
        );
        _transfer(from, to, value);
        return true;
    }

    function mint(uint256 value) external onlyAuthority returns (bool) {
        _totalSupply = _totalSupply.add(value);
        _balances[msg.sender] = _balances[msg.sender].add(value);
        emit Transfer(address(0), msg.sender, value);
        return true;
    }

    function burn(uint256 value) external onlyAuthority returns (bool) {
        _balances[msg.sender] = _balances[msg.sender].sub(
            value,
            "ERC20/Not-Enough-Balance"
        );
        _totalSupply = _totalSupply.sub(value);
        emit Transfer(msg.sender, address(0), value);
        return true;
    }

    /**
     * @notice Update allowance with a signed permit
     * @param owner       Token owner's address (Authorizer)
     * @param spender     Spender's address
     * @param value       Amount of allowance
     * @param deadline    Expiration time, seconds since the epoch
     * @param v           v of the signature
     * @param r           r of the signature
     * @param s           s of the signature
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        _permit(owner, spender, value, deadline, v, r, s);
    }

    function supportsInterface(bytes4 interfaceID)
        external
        view
        override
        returns (bool)
    {
        return
            interfaceID == type(IERC20).interfaceId || // ERC20
            interfaceID == type(IERC165).interfaceId || // ERC165
            interfaceID == type(IERC173).interfaceId || // ERC173
            interfaceID == type(IERC2612).interfaceId ||
            interfaceID == type(Iinitialize).interfaceId; // ERC2612
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal override {
        require(to != address(this), "ERC20/Not-Allowed-Transfer");
        _balances[from] = _balances[from].sub(
            value,
            "ERC20/Not-Enough-Balance"
        );
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    function _approve(
        address owner,
        address spender,
        uint256 value
    ) internal override {
        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }
}
