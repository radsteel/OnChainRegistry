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

    // Optimization: Using calldata for string parameters reduces gas by avoiding memory allocations
    function registerMember(string calldata _name, uint256 _age) public{
        require (!addressToMember[msg.sender].isRegistered, "User is already registered!");
        uint256 newIndex = members.length;
        Member memory newMember = Member(msg.sender, _name, _age, newIndex, true);
        members.push(newMember);
        addressToMember[msg.sender] = newMember;
        emit MemberRegistered(msg.sender, _name, _age);
    }

    // Optimization: Storage pointers and unchecked arithmetic optimize gas during swap-and-pop removal
    function removeMember() public{
        Member storage member = addressToMember[msg.sender];
        require(member.isRegistered, "User is not registered!");
        uint256 indexToRemove = member.index;
        string memory removedName = member.name;
        uint256 removedAge = member.age;

        uint256 lastIndex;
        // Optimization: Unchecked math saves gas since length > 0 is guaranteed by isRegistered guard
        unchecked {
            lastIndex = members.length - 1;
        }
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

    // Optimization: Storage pointers minimize gas consumption for profile updates
    function updateMember(string calldata _name, uint256 _age) public{
        Member storage member = addressToMember[msg.sender];
        require(member.isRegistered, "User is not registered!");
        uint256 memberIndex = member.index;
        member.name = _name;
        member.age = _age;

        Member storage memberInArr = members[memberIndex];
        memberInArr.name = _name;
        memberInArr.age = _age;

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
