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

    // Optimization: Custom errors save deployment gas and execution gas compared to require strings
    error AlreadyRegistered();
    error NotRegistered();
    error IndexOutOfBounds();

    event MemberRegistered(address indexed walletAddress, string name, uint256 age);
    event MemberRemoved(address indexed walletAddress, string name, uint256 age);
    event MemberUpdated(address indexed walletAddress, string name, uint256 age);

    // Optimization: Using calldata for string parameters reduces gas by avoiding memory allocations
    function registerMember(string calldata _name, uint256 _age) public{
        if (addressToMember[msg.sender].isRegistered) revert AlreadyRegistered();
        uint256 newIndex = members.length;
        Member memory newMember = Member(msg.sender, _name, _age, newIndex, true);
        members.push(newMember);
        addressToMember[msg.sender] = newMember;
        emit MemberRegistered(msg.sender, _name, _age);
    }

    // Optimization: Storage pointers and unchecked arithmetic reduce gas on removal
    function removeMember() public{
        Member storage member = addressToMember[msg.sender];
        if (!member.isRegistered) revert NotRegistered();
        uint256 indexToRemove = member.index;
        string memory removedName = member.name;
        uint256 removedAge = member.age;

        // Optimization: Safe to use unchecked subtraction since member.isRegistered guarantees members.length > 0
        unchecked {
            uint256 lastIndex = members.length - 1;
            if(indexToRemove != lastIndex){
                Member storage lastMember = members[lastIndex];
                lastMember.index = indexToRemove;
                members[indexToRemove] = lastMember;
                addressToMember[lastMember.walletAddress].index = indexToRemove;
            }
        }
        members.pop();
        delete addressToMember[msg.sender];
        emit MemberRemoved(msg.sender, removedName, removedAge);
    }

    // Optimization: Storage pointers minimize gas consumption for profile updates
    function updateMember(string calldata _name, uint256 _age) public{
        Member storage member = addressToMember[msg.sender];
        if (!member.isRegistered) revert NotRegistered();
        uint256 memberIndex = member.index;
        member.name = _name;
        member.age = _age;

        // Optimization: Caching members[memberIndex] as a storage pointer avoids repeated array index overhead
        Member storage arrayMember = members[memberIndex];
        arrayMember.name = _name;
        arrayMember.age = _age;

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
