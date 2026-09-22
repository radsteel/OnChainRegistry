//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Registry{
    struct Member {
        address walletAddress;
        string name;
        uint256 age;
        uint256 index;
        bool isRegistered;
    }
    Member[] public members;
    mapping(address => Member) public addressToMember;

    event MemberRegistered(address indexed walletAddress, string name, uint256 age);
    event MemberRemoved(address indexed walletAddress, string name, uint256 age);
    event MemberUpdated(address indexed walletAddress, string name, uint256 age);

    // Gas Optimization:
    // 1. Using `external` visibility instead of `public` saves gas by avoiding unnecessary array/string parameter copying to memory.
    // 2. Using `calldata` for string parameters avoids copying memory allocation overhead.
    // 3. Caching mapping storage pointer `addressToMember[msg.sender]` avoids repeated mapping lookups / keccak256 hash recalculations and redundant SLOAD operations.

    function registerMember(string calldata _name, uint256 _age) external {
        Member storage senderMember = addressToMember[msg.sender];
        require(!senderMember.isRegistered, "User is already registered!");
        uint256 newIndex = members.length;

        senderMember.walletAddress = msg.sender;
        senderMember.name = _name;
        senderMember.age = _age;
        senderMember.index = newIndex;
        senderMember.isRegistered = true;

        members.push(senderMember);

        emit MemberRegistered(msg.sender, _name, _age);
    }

    function removeMember() external {
        Member storage senderMember = addressToMember[msg.sender];
        require(senderMember.isRegistered, "User is not registered!");

        uint256 indexToRemove = senderMember.index;
        uint256 lastIndex = members.length - 1;

        if(indexToRemove != lastIndex){
            Member storage lastMember = members[lastIndex];
            members[indexToRemove] = lastMember;
            members[indexToRemove].index = indexToRemove;
            addressToMember[lastMember.walletAddress].index = indexToRemove;
        }

        string memory removedName = senderMember.name;
        uint256 removedAge = senderMember.age;

        members.pop();
        delete addressToMember[msg.sender];

        emit MemberRemoved(msg.sender, removedName, removedAge);
    }

    function updateMember(string calldata _name, uint256 _age) external {
        Member storage senderMember = addressToMember[msg.sender];
        require(senderMember.isRegistered, "User is not registered!");

        uint256 memberIndex = senderMember.index;
        senderMember.name = _name;
        senderMember.age = _age;
        members[memberIndex].name = _name;
        members[memberIndex].age = _age;

        emit MemberUpdated(msg.sender, _name, _age);
    }

    function getAllMembers() external view returns(Member[] memory){
        return members;
    }

    function getMemberByIndex(uint256 _index) external view returns(Member memory){
        require(_index < members.length, "Index out of bounds!");
        return members[_index];
    }

    function getMember(address _memberAddress) external view returns (Member memory){
        return addressToMember[_memberAddress];
    }

    function getTotalMembers() external view returns(uint256){
        return members.length;
    }

    function isMemberRegistered(address _memberAddress) external view returns(bool){
        return addressToMember[_memberAddress].isRegistered;
    }
}