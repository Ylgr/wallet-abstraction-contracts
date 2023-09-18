//// SPDX-License-Identifier: UNLICENSED
//pragma solidity ^0.8.13;
//
//import "forge-std/Test.sol";
//import "../src/BicAccount.sol";
//import "../src/utils/Entrypoint.sol";
//
//contract AccountTest is Test {
//    Account public account;
//    IEntryPoint public entrypoint;
//
//    function setUp() public {
//        entrypoint = new EntryPoint();
//        account = new Account();
//    }
//
//    function testAccount() public {
//        assertEq(account.getNonce(address(this), 0), 0);
//        account.incrementNonce(0);
//        assertEq(account.getNonce(address(this), 0), 1);
//        account.incrementNonce(0);
//        assertEq(account.getNonce(address(this), 0), 2);
//    }
//}
