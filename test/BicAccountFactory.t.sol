// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/BicAccount.sol";
import "../src/BicAccountFactory.sol";
import "../src/utils/Entrypoint.sol";

contract BicAccountFactoryTest is Test {
    BicAccountFactory public accountFactory;
    IEntryPoint public entrypoint;
    address public user1 = address(0x1);
    address public user2 = address(0x2);

    function setUp() public {
        entrypoint = new EntryPoint();
        console.log("1");
        accountFactory = new BicAccountFactory(entrypoint);
        console.log("2");
    }

    function test_createAccount() public {
        address accountAddress = accountFactory.createAccount(msg.sender, "");
        BicAccount account = BicAccount(payable(accountAddress));
        assertEq(account.getNonce(), 0);
        assertEq(account.isAdmin(msg.sender), true);
        assertEq(account.isAdmin(accountFactory.recoveryAddress()), true);
        assertEq(account.factory(), address(accountFactory));
        assertEq(address(account.entryPoint()), address(entrypoint));
    }

    function test_accountAddress() public {
        vm.prank(user1);
        address accountAddressUser1 = accountFactory.getAddress(user1, "");
        assertEq(accountAddressUser1, address(0x3dC618d38C9A777912bFBF3A1a4cb97c7989A4bA));
        vm.prank(user2);
        address accountAddressUser2 = accountFactory.getAddress(user2, "");
        assertEq(accountAddressUser2, address(0x2C8947bC22e7a66DAD08b9a1b07cf8c086F78479));

        assertEq(accountFactory.getAddress(user1, ""), accountFactory.getAddress(user1, "sadasdsada"));
    }

    function test_recoverAdmin() public {
        vm.prank(user1);
        address accountAddressUser1 = accountFactory.createAccount(user1, "");
        BicAccount account = BicAccount(payable(accountAddressUser1));
        assertEq(account.isAdmin(user1), true);
        assertEq(account.isAdmin(user2), false);
        assertEq(account.isAdmin(accountFactory.recoveryAddress()), true);

        vm.prank(accountFactory.recoveryAddress());
        account.setAdmin(user2, true);
        account.setAdmin(user1, false);
        assertEq(account.isAdmin(user1), false);
        assertEq(account.isAdmin(user2), true);
    }
}
