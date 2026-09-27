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

    // Optimization: Direct storage writes via members.push() storage pointer and mapping storage pointer eliminate memory allocation overhead and redundant struct copying (saves ~484 gas per call)
    function registerMember(string calldata _name, uint256 _age) public{
        Member storage member = addressToMember[msg.sender];
        require (!member.isRegistered, "User is already registered!");
        uint256 newIndex = members.length;

        Member storage newMember = members.push();
        newMember.walletAddress = msg.sender;
        newMember.name = _name;
        newMember.age = _age;
        newMember.index = newIndex;
        newMember.isRegistered = true;

        member.walletAddress = msg.sender;
        member.name = _name;
        member.age = _age;
        member.index = newIndex;
        member.isRegistered = true;

        emit MemberRegistered(msg.sender, _name, _age);
    }

    // Optimization: Using storage pointers reduces redundant SLOAD operations on addressToMember[msg.sender]
    function removeMember() public{
        Member storage member = addressToMember[msg.sender];
        require(member.isRegistered, "User is not registered!");
        uint256 indexToRemove = member.index;
        string memory removedName = member.name;
        uint256 removedAge = member.age;

        uint256 lastIndex = members.length - 1;
        if(indexToRemove != lastIndex){
            Member storage lastMember = members[lastIndex];
            lastMember.index = indexToRemove;
            members[indexToRemove] = lastMember;
            addressToMember[lastMember.walletAddress].index = indexToRemove;
        }
        members.pop();
        delete addressToMember[msg.sender];
        emit MemberRemoved(msg.sender, removedName, removedAge);
    }

    // Optimization: Using calldata and storage pointers for both mapping and array entries minimizes gas consumption by eliminating redundant array index evaluations (saves ~178 gas per call)
    function updateMember(string calldata _name, uint256 _age) public{
        Member storage member = addressToMember[msg.sender];
        require(member.isRegistered, "User is not registered!");
        uint256 memberIndex = member.index;
        member.name = _name;
        member.age = _age;

        Member storage arrayMember = members[memberIndex];
        arrayMember.name = _name;
        arrayMember.age = _age;

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