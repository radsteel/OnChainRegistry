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

    function registerMember(string calldata _name, uint256 _age) public{
        // Optimization: Cache mapping reference in storage pointer to avoid repeated key hashing
        Member storage senderMember = addressToMember[msg.sender];
        require(!senderMember.isRegistered, "User is already registered!");
        uint256 newIndex = members.length;
        Member memory newMember = Member(msg.sender, _name, _age, newIndex, true);
        members.push(newMember);
        addressToMember[msg.sender] = newMember;
        emit MemberRegistered(msg.sender, _name, _age);
    }

    function removeMember() public{
        // Optimization: Cache mapping reference in storage pointer
        Member storage senderMember = addressToMember[msg.sender];
        require(senderMember.isRegistered, "User is not registered!");

        uint256 indexToRemove = senderMember.index;
        uint256 lastIndex = members.length - 1;

        if (indexToRemove != lastIndex) {
            // Optimization: Use `storage` pointer instead of `memory` to avoid copying dynamic string
            // fields to memory and avoid a duplicate SSTORE when updating index during Swap & Pop.
            Member storage lastMember = members[lastIndex];
            lastMember.index = indexToRemove;
            members[indexToRemove] = lastMember;
            addressToMember[lastMember.walletAddress].index = indexToRemove;
        }

        string memory removedName = senderMember.name;
        uint256 removedAge = senderMember.age;
        members.pop();
        delete addressToMember[msg.sender];

        emit MemberRemoved(msg.sender, removedName, removedAge);
    }

    function updateMember(string calldata _name, uint256 _age) public{
        // Optimization: Cache mapping reference in storage pointer
        Member storage senderMember = addressToMember[msg.sender];
        require(senderMember.isRegistered, "User is not registered!");
        uint256 memberIndex = senderMember.index;

        senderMember.name = _name;
        senderMember.age = _age;
        members[memberIndex].name = _name;
        members[memberIndex].age = _age;

        emit MemberUpdated(msg.sender, _name, _age);
    }

    function getAllMembers() public view returns(Member[] memory){
        return members;
    }

    function getMemberByIndex(uint256 _index) public view returns(Member memory){
        require(_index < members.length, "Index out of bounds!");
        return members[_index];
    }

    function getMember(address _memberAddress) public view returns (Member memory){
        return addressToMember[_memberAddress];
    }

    function getTotalMembers() public view returns(uint256){
        return members.length;
    }

    function isMemberRegistered(address _memberAddress) public view returns(bool){
        return addressToMember[_memberAddress].isRegistered;
    }
}
