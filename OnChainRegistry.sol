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

    function registerMember(string memory _name, uint256 _age) public{
        // Gas Optimization: Cache mapping pointer to avoid multiple storage lookup evaluations
        Member storage senderMember = addressToMember[msg.sender];
        require (!senderMember.isRegistered, "User is already registered!");
        uint256 newIndex = members.length;
        Member memory newMember = Member(msg.sender, _name, _age, newIndex, true);
        members.push(newMember);
        addressToMember[msg.sender] = newMember;
        emit MemberRegistered(msg.sender, _name, _age);
    }
    function removeMember() public{
        // Gas Optimization: Cache storage pointer to eliminate duplicate SLOADs for addressToMember[msg.sender]
        Member storage senderMember = addressToMember[msg.sender];
        require(senderMember.isRegistered, "User is not registered!");
        uint256 indexToRemove = senderMember.index;
        string memory removedName = senderMember.name;
        uint256 removedAge = senderMember.age;
        uint256 lastIndex = members.length - 1;
        if(indexToRemove != lastIndex){
            Member memory lastMember = members[lastIndex];
            members[indexToRemove] = lastMember;
            members[indexToRemove].index = indexToRemove;
            addressToMember[lastMember.walletAddress].index = indexToRemove;
        }
        members.pop();
        delete addressToMember[msg.sender];
        emit MemberRemoved(msg.sender, removedName, removedAge);
    }
    function updateMember(string memory _name, uint256 _age) public{
        // Gas Optimization: Cache storage pointer to eliminate redundant SLOADs and SSTORE computations
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