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

    function registerMember(string memory _name, uint256 _age) public {
        // Gas optimization: Cache storage pointer to eliminate redundant mapping hash calculations
        Member storage user = addressToMember[msg.sender];
        require(!user.isRegistered, "User is already registered!");

        uint256 newIndex = members.length;
        Member memory newMember = Member(msg.sender, _name, _age, newIndex, true);
        members.push(newMember);
        addressToMember[msg.sender] = newMember;

        emit MemberRegistered(msg.sender, _name, _age);
    }

    function removeMember() public {
        // Gas optimization: Cache user storage pointer to prevent repeated mapping lookups
        Member storage user = addressToMember[msg.sender];
        require(user.isRegistered, "User is not registered!");

        uint256 indexToRemove = user.index;
        uint256 lastIndex = members.length - 1;

        if (indexToRemove != lastIndex) {
            // Gas optimization: Use storage pointer for direct storage-to-storage copy,
            // avoiding costly storage-to-memory copy and string memory allocation
            Member storage lastMember = members[lastIndex];
            addressToMember[lastMember.walletAddress].index = indexToRemove;
            lastMember.index = indexToRemove;
            members[indexToRemove] = lastMember;
        }

        string memory removedName = user.name;
        uint256 removedAge = user.age;

        members.pop();
        delete addressToMember[msg.sender];

        emit MemberRemoved(msg.sender, removedName, removedAge);
    }

    function updateMember(string memory _name, uint256 _age) public {
        // Gas optimization: Cache storage pointers to minimize SLOADs and mapping slot address re-computations
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