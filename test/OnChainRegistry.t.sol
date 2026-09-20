// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../OnChainRegistry.sol";

contract RegistryTest is Test {
    Registry public registry;

    address user1 = address(0x1);
    address user2 = address(0x2);
    address user3 = address(0x3);

    function setUp() public {
        registry = new Registry();
    }

    function testRegisterMember() public {
        vm.startPrank(user1);
        registry.registerMember("Alice", 25);
        vm.stopPrank();

        assertTrue(registry.isMemberRegistered(user1));
        assertEq(registry.getTotalMembers(), 1);

        Registry.Member memory member = registry.getMember(user1);
        assertEq(member.name, "Alice");
        assertEq(member.age, 25);
        assertEq(member.index, 0);
        assertTrue(member.isRegistered);
    }

    function testUpdateMember() public {
        vm.startPrank(user1);
        registry.registerMember("Alice", 25);
        registry.updateMember("Alice Updated", 26);
        vm.stopPrank();

        Registry.Member memory member = registry.getMember(user1);
        assertEq(member.name, "Alice Updated");
        assertEq(member.age, 26);

        Registry.Member memory arrayMember = registry.getMemberByIndex(0);
        assertEq(arrayMember.name, "Alice Updated");
        assertEq(arrayMember.age, 26);
    }

    function testRemoveMember() public {
        vm.startPrank(user1);
        registry.registerMember("Alice", 25);
        vm.stopPrank();

        vm.startPrank(user2);
        registry.registerMember("Bob", 30);
        vm.stopPrank();

        vm.startPrank(user3);
        registry.registerMember("Charlie", 35);
        vm.stopPrank();

        assertEq(registry.getTotalMembers(), 3);

        // Remove middle member (Bob)
        vm.startPrank(user2);
        registry.removeMember();
        vm.stopPrank();

        assertEq(registry.getTotalMembers(), 2);
        assertFalse(registry.isMemberRegistered(user2));

        // Check that Charlie was moved to index 1
        Registry.Member memory charlie = registry.getMember(user3);
        assertEq(charlie.index, 1);

        Registry.Member memory memberAtIndex1 = registry.getMemberByIndex(1);
        assertEq(memberAtIndex1.walletAddress, user3);
        assertEq(memberAtIndex1.index, 1);

        // Remove last member (Charlie)
        vm.startPrank(user3);
        registry.removeMember();
        vm.stopPrank();

        assertEq(registry.getTotalMembers(), 1);

        // Remove remaining member (Alice)
        vm.startPrank(user1);
        registry.removeMember();
        vm.stopPrank();

        assertEq(registry.getTotalMembers(), 0);
    }

    function test_RevertWhen_RegisterTwice() public {
        vm.startPrank(user1);
        registry.registerMember("Alice", 25);
        vm.expectRevert("User is already registered!");
        registry.registerMember("Alice", 25);
        vm.stopPrank();
    }

    function test_RevertWhen_RemoveUnregistered() public {
        vm.startPrank(user1);
        vm.expectRevert("User is not registered!");
        registry.removeMember();
        vm.stopPrank();
    }

    function test_RevertWhen_UpdateUnregistered() public {
        vm.startPrank(user1);
        vm.expectRevert("User is not registered!");
        registry.updateMember("Alice", 25);
        vm.stopPrank();
    }
}
