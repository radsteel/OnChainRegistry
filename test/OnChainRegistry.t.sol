// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../OnChainRegistry.sol";

contract RegistryTest {
    Registry public registry;

    function setUp() public {
        registry = new Registry();
    }

    function testRegisterMember() public {
        registry.registerMember("Alice", 25);

        (address walletAddress, string memory name, uint256 age, uint256 index, bool isRegistered) = registry.members(0);
        require(walletAddress == address(this), "Wallet mismatch");
        require(keccak256(bytes(name)) == keccak256(bytes("Alice")), "Name mismatch");
        require(age == 25, "Age mismatch");
        require(index == 0, "Index mismatch");
        require(isRegistered, "Should be registered");

        require(registry.isMemberRegistered(address(this)), "Is registered mismatch");
        require(registry.getTotalMembers() == 1, "Total members mismatch");
    }

    function testUpdateMember() public {
        registry.registerMember("Alice", 25);
        registry.updateMember("Alice Updated", 26);

        (, string memory name, uint256 age, , ) = registry.members(0);
        require(keccak256(bytes(name)) == keccak256(bytes("Alice Updated")), "Updated name mismatch");
        require(age == 26, "Updated age mismatch");

        Registry.Member memory member = registry.getMember(address(this));
        require(keccak256(bytes(member.name)) == keccak256(bytes("Alice Updated")), "Mapping updated name mismatch");
        require(member.age == 26, "Mapping updated age mismatch");
    }

    function testRemoveMember() public {
        registry.registerMember("Alice", 25);
        registry.removeMember();

        require(!registry.isMemberRegistered(address(this)), "Should not be registered");
        require(registry.getTotalMembers() == 0, "Total members should be 0");
    }

    function testSwapAndPopRemoval() public {
        registry.registerMember("User1", 20);

        UserHelper user2 = new UserHelper(registry);
        user2.register("User2", 30);

        require(registry.getTotalMembers() == 2, "Total members should be 2");

        registry.removeMember();

        require(registry.getTotalMembers() == 1, "Total members should be 1 after removal");

        Registry.Member memory remainingMember = registry.getMemberByIndex(0);
        require(remainingMember.walletAddress == address(user2), "Swapped wallet mismatch");
        require(remainingMember.index == 0, "Swapped index mismatch");
    }
}

contract UserHelper {
    Registry public registry;

    constructor(Registry _registry) {
        registry = _registry;
    }

    function register(string memory name, uint256 age) external {
        registry.registerMember(name, age);
    }

    function remove() external {
        registry.removeMember();
    }
}
