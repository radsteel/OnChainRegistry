//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// Custom errors reduce deployment size and execution gas compared to require error strings
error UserAlreadyRegistered();
error UserNotRegistered();
error IndexOutOfBounds();

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

    // Optimization: Using calldata and custom error reduces gas by avoiding memory allocations and string storage
    function registerMember(string calldata _name, uint256 _age) public{
        if (addressToMember[msg.sender].isRegistered) revert UserAlreadyRegistered();
        uint256 newIndex = members.length;
        Member memory newMember = Member(msg.sender, _name, _age, newIndex, true);
        members.push(newMember);
        addressToMember[msg.sender] = newMember;
        emit MemberRegistered(msg.sender, _name, _age);
    }

    // Optimization: Emitting event directly before deletion avoids extra string variable allocation in memory
    function removeMember() public{
        Member storage member = addressToMember[msg.sender];
        if (!member.isRegistered) revert UserNotRegistered();
        uint256 indexToRemove = member.index;

        emit MemberRemoved(msg.sender, member.name, member.age);

        uint256 lastIndex = members.length - 1;
        if(indexToRemove != lastIndex){
            Member storage lastMember = members[lastIndex];
            lastMember.index = indexToRemove;
            members[indexToRemove] = lastMember;
            addressToMember[lastMember.walletAddress].index = indexToRemove;
        }
        members.pop();
        delete addressToMember[msg.sender];
    }

    // Optimization: Storage pointers for both mapping and array avoid redundant SLOAD operations
    function updateMember(string calldata _name, uint256 _age) public{
        Member storage member = addressToMember[msg.sender];
        if (!member.isRegistered) revert UserNotRegistered();
        Member storage arrMember = members[member.index];
        member.name = _name;
        member.age = _age;
        arrMember.name = _name;
        arrMember.age = _age;

        emit MemberUpdated(msg.sender, _name, _age);
    }
    function getAllMembers() public view returns(Member[] memory){
        return members;
    }
    function getMemberByIndex(uint256 _index) public view returns(Member memory){
        if (_index >= members.length) revert IndexOutOfBounds();
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
