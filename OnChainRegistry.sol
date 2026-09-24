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

    // Gas Optimization: Use calldata instead of memory for string input to avoid copying from calldata to memory
    function registerMember(string calldata _name, uint256 _age) public{
        require (!addressToMember[msg.sender].isRegistered, "User is already registered!");
        uint256 newIndex = members.length;
        Member memory newMember = Member(msg.sender, _name, _age, newIndex, true);
        members.push(newMember);
        addressToMember[msg.sender] = newMember;
        emit MemberRegistered(msg.sender, _name, _age);
    }

    function removeMember() public{
        // Gas Optimization: Cache mapping pointer in storage to avoid redundant keccak256 hash calculations
        Member storage memberToRemove = addressToMember[msg.sender];
        require(memberToRemove.isRegistered, "User is not registered!");
        uint256 indexToRemove = memberToRemove.index;
        uint256 lastIndex = members.length - 1;
        if(indexToRemove != lastIndex){
            Member memory lastMember = members[lastIndex];
            members[indexToRemove] = lastMember;
            members[indexToRemove].index = indexToRemove;
            addressToMember[lastMember.walletAddress].index = indexToRemove;
        }
        string memory removedName = memberToRemove.name;
        uint256 removedAge = memberToRemove.age;
        members.pop();
        delete addressToMember[msg.sender];
        emit MemberRemoved(msg.sender, removedName, removedAge);
    }

    // Gas Optimization: Use calldata for read-only string input and cache storage references to avoid redundant mapping lookups
    function updateMember(string calldata _name, uint256 _age) public{
        Member storage memberToUpdate = addressToMember[msg.sender];
        require(memberToUpdate.isRegistered, "User is not registered!");
        uint256 memberIndex = memberToUpdate.index;
        memberToUpdate.name = _name;
        memberToUpdate.age = _age;
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