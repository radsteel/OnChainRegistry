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

    // Gas Optimization: String parameters modified to `calldata` location to avoid unnecessary memory allocations/copies.
    // Gas Optimization: External visibility used for contract functions called externally to optimize calldata decoding.
    function registerMember(string calldata _name, uint256 _age) external {
        require (!addressToMember[msg.sender].isRegistered, "User is already registered!");
        uint256 newIndex = members.length;
        Member memory newMember = Member(msg.sender, _name, _age, newIndex, true);
        members.push(newMember);
        addressToMember[msg.sender] = newMember;
        emit MemberRegistered(msg.sender, _name, _age);
    }

    function removeMember() external {
        // Gas Optimization: Cache mapping reference as storage pointer to avoid repeated mapping lookups / SLOADs.
        Member storage memberToRemove = addressToMember[msg.sender];
        require(memberToRemove.isRegistered, "User is not registered!");

        uint256 indexToRemove = memberToRemove.index;
        uint256 lastIndex = members.length - 1;

        string memory removedName = memberToRemove.name;
        uint256 removedAge = memberToRemove.age;

        if(indexToRemove != lastIndex){
            Member storage lastMember = members[lastIndex];
            members[indexToRemove] = lastMember;
            members[indexToRemove].index = indexToRemove;
            addressToMember[lastMember.walletAddress].index = indexToRemove;
        }

        members.pop();
        delete addressToMember[msg.sender];
        emit MemberRemoved(msg.sender, removedName, removedAge);
    }

    function updateMember(string calldata _name, uint256 _age) external {
        // Gas Optimization: Storage pointer used to avoid repeated mapping key evaluation.
        Member storage memberToUpdate = addressToMember[msg.sender];
        require(memberToUpdate.isRegistered, "User is not registered!");

        uint256 memberIndex = memberToUpdate.index;

        memberToUpdate.name = _name;
        memberToUpdate.age = _age;

        Member storage arrayMember = members[memberIndex];
        arrayMember.name = _name;
        arrayMember.age = _age;

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
