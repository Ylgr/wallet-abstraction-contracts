// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/BicAccount.sol";
import "../src/BicAccountFactory.sol";
import "../src/utils/Entrypoint.sol";
import "../src/test/TestToken.sol";

contract BicAccountFactoryTest is Test {
    BicAccountFactory public accountFactory;
    EntryPoint public entrypoint;
    uint256 public user1PKey = 0x1;
    address public user1 = vm.addr(user1PKey);
    uint256 public user2PKey = 0x2;
    address public user2 = vm.addr(user2PKey);
    address public randomExecuteer = address(0x3);
    function setUp() public {
        entrypoint = new EntryPoint();
        console.log("1");
        accountFactory = new BicAccountFactory(entrypoint);
        console.log("2");
    }


    function _setupUserOp(
        uint256 _signerPKey,
        bytes memory _initCode,
        bytes memory _callDataForEntrypoint,
        address sender
    ) internal returns (UserOperation[] memory ops) {
        uint256 nonce = entrypoint.getNonce(sender, 0);

        // Get user op fields
        UserOperation memory op = UserOperation({
            sender: sender,
            nonce: nonce,
            initCode: _initCode,
            callData: _callDataForEntrypoint,
            callGasLimit: 500_000,
            verificationGasLimit: 500_000,
            preVerificationGas: 500_000,
            maxFeePerGas: 0,
            maxPriorityFeePerGas: 0,
            paymasterAndData: bytes(""),
            signature: bytes("")
        });

        // Sign UserOp
        bytes32 opHash = EntryPoint(entrypoint).getUserOpHash(op);
        bytes32 msgHash = ECDSA.toEthSignedMessageHash(opHash);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_signerPKey, msgHash);
        bytes memory userOpSignature = abi.encodePacked(r, s, v);

        op.signature = userOpSignature;

        // Store UserOp
        ops = new UserOperation[](1);
        ops[0] = op;
    }

    function _setupUserOpExecute(
        uint256 _signerPKey,
        bytes memory _initCode,
        address _target,
        uint256 _value,
        bytes memory _callData,
        address sender
    ) internal returns (UserOperation[] memory) {
        bytes memory callDataForEntrypoint = abi.encodeWithSignature(
            "execute(address,uint256,bytes)",
            _target,
            _value,
            _callData
        );

        return _setupUserOp(_signerPKey, _initCode, callDataForEntrypoint, sender);
    }

    function _setupUserOpExecuteBatch(
        uint256 _signerPKey,
        bytes memory _initCode,
        address[] memory _target,
        uint256[] memory _value,
        bytes[] memory _callData,
        address sender
    ) internal returns (UserOperation[] memory) {
        bytes memory callDataForEntrypoint = abi.encodeWithSignature(
            "executeBatch(address[],uint256[],bytes[])",
            _target,
            _value,
            _callData
        );

        return _setupUserOp(_signerPKey, _initCode, callDataForEntrypoint, sender);
    }

    function test_createAccount() public {
        address accountAddress = accountFactory.createAccount(msg.sender, "");
        BicAccount account = BicAccount(payable(accountAddress));
        assertEq(account.getNonce(), 0);
        assertEq(account.isAdmin(msg.sender), true);
        assertEq(account.isAdmin(accountFactory.recoveryAddress()), true);
        assertEq(account.factory(), address(accountFactory));
        assertEq(address(account.entryPoint()), address(entrypoint));

        bytes memory initCallData = abi.encodeWithSignature("createAccount(address,bytes)", user1, bytes(""));
        bytes memory initCode = abi.encodePacked(abi.encodePacked(address(accountFactory)), initCallData);
        address user1AccountAddress = accountFactory.getAddress(user1, "");
        UserOperation[] memory userOpCreateAccount = _setupUserOpExecute(
            user1PKey,
            initCode,
            address(0),
            0,
            bytes(""),
            user1AccountAddress
        );

        EntryPoint(entrypoint).handleOps(userOpCreateAccount, payable(user1));
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

    function test_sendErc20Token() public {
        vm.prank(user1);
        address accountAddress1 = accountFactory.createAccount(user1, "");
        BicAccount account1 = BicAccount(payable(accountAddress1));
        assertEq(account1.getNonce(), 0);
        assertEq(account1.isAdmin(user1), true);

        TestToken token = new TestToken();
        token.mint(accountAddress1, 100);
        assertEq(token.balanceOf(accountAddress1), 100);

        vm.prank(user2);
        address accountAddress2 = accountFactory.createAccount(user2, "");
        BicAccount account2 = BicAccount(payable(accountAddress2));
        assertEq(account2.getNonce(), 0);
        assertEq(account2.isAdmin(user2), true);

        vm.prank(user1);
    }
}
