//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Registry {
    // Gas Optimization: Struct Packing
    // `walletAddress` (20 bytes) and `isRegistered` (1 byte) are packed into a single 32-byte storage slot (Slot 0),
    // reducing total storage slots per member from 5 to 4.
    struct Member {
        address walletAddress; // 20 bytes
        bool isRegistered;     // 1 byte (packed into same 32-byte slot with walletAddress)
        uint256 age;           // 32 bytes
        uint256 index;         // 32 bytes
        string name;           // dynamic
    }
    Member[] public members;
    mapping(address => Member) public addressToMember;

    event MemberRegistered(address indexed walletAddress, string name, uint256 age);
    event MemberRemoved(address indexed walletAddress, string name, uint256 age);
    event MemberUpdated(address indexed walletAddress, string name, uint256 age);

    // Gas Optimization: Using `calldata` for string parameters avoids copying bytes from transaction payload to memory.
    function registerMember(string calldata _name, uint256 _age) public {
        // Gas Optimization: Storage pointer caches lookup to avoid duplicate SLOAD instructions.
        Member storage member = addressToMember[msg.sender];
        require(!member.isRegistered, "User is already registered!");

        uint256 newIndex = members.length;
        Member memory newMember = Member(msg.sender, true, _age, newIndex, _name);
        members.push(newMember);
        addressToMember[msg.sender] = newMember;

        emit MemberRegistered(msg.sender, _name, _age);
    }

    function removeMember() public {
        // Gas Optimization: Storage pointer caches lookup to avoid duplicate SLOAD instructions.
        Member storage memberToRemove = addressToMember[msg.sender];
        require(memberToRemove.isRegistered, "User is not registered!");

        uint256 indexToRemove = memberToRemove.index;
        string memory removedName = memberToRemove.name;
        uint256 removedAge = memberToRemove.age;
        uint256 lastIndex = members.length - 1;

        if (indexToRemove != lastIndex) {
            Member storage lastMember = members[lastIndex];
            lastMember.index = indexToRemove;
            members[indexToRemove] = lastMember;
            addressToMember[lastMember.walletAddress].index = indexToRemove;
        }

        members.pop();
        delete addressToMember[msg.sender];

        emit MemberRemoved(msg.sender, removedName, removedAge);
    }

    // Gas Optimization: Using `calldata` for string parameters avoids copying bytes from transaction payload to memory.
    function updateMember(string calldata _name, uint256 _age) public {
        // Gas Optimization: Storage pointer caches lookup to avoid duplicate SLOAD instructions.
        Member storage member = addressToMember[msg.sender];
        require(member.isRegistered, "User is not registered!");

        member.name = _name;
        member.age = _age;

        Member storage arrayMember = members[member.index];
        arrayMember.name = _name;
        arrayMember.age = _age;

        emit MemberUpdated(msg.sender, _name, _age);
    }

    function getAllMembers() public view returns (Member[] memory) {
        return members;
    }

    function getMemberByIndex(uint256 _index) public view returns (Member memory) {
        require(_index < members.length, "Index out of bounds!");
        return members[_index];
    }

    function getMember(address _memberAddress) public view returns (Member memory) {
        return addressToMember[_memberAddress];
    }

    function getTotalMembers() public view returns (uint256) {
        return members.length;
    }

    function isMemberRegistered(address _memberAddress) public view returns (bool) {
        return addressToMember[_memberAddress].isRegistered;
    }
}
