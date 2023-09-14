// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/test/TestToken.sol";

contract TestTokenTest is Test {
    TestToken public token;

    function setUp() public {
        token = new TestToken();
    }

    function testTokenName() public {
        assertEq(token.name(), "TestToken");
    }

    function testTokenSymbol() public {
        assertEq(token.symbol(), "TT");
    }

    function testTokenDecimals() public {
        assertEq(token.decimals(), 18);
    }

    function testTokenTotalSupply() public {
        assertEq(token.totalSupply(), 10000000 * 10**18);
    }

    function testTokenBalanceOf() public {
        assertEq(token.balanceOf(address(this)), 10000000 * 10**18);
    }
}
