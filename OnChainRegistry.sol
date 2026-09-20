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

    // GAS OPTIMIZATION: Use string calldata parameter location to avoid calldata-to-memory copy overhead
    function registerMember(string calldata _name, uint256 _age) public{
        // GAS OPTIMIZATION: Cache mapping storage reference to reduce base slot recalculation and redundant SLOAD
        Member storage senderMember = addressToMember[msg.sender];
        require (!senderMember.isRegistered, "User is already registered!");
        uint256 newIndex = members.length;
        members.push(Member(msg.sender, _name, _age, newIndex, true));

        senderMember.walletAddress = msg.sender;
        senderMember.name = _name;
        senderMember.age = _age;
        senderMember.index = newIndex;
        senderMember.isRegistered = true;

        emit MemberRegistered(msg.sender, _name, _age);
    }

    function removeMember() public{
        // GAS OPTIMIZATION: Cache mapping storage pointer to avoid repeating SLOADs and mapping key hashing
        Member storage senderMember = addressToMember[msg.sender];
        require(senderMember.isRegistered, "User is not registered!");
        uint256 indexToRemove = senderMember.index;
        string memory removedName = senderMember.name;
        uint256 removedAge = senderMember.age;

        uint256 lastIndex = members.length - 1;
        if(indexToRemove != lastIndex){
            // GAS OPTIMIZATION: Use storage reference for last member to reduce memory copy allocation overhead
            Member storage lastMember = members[lastIndex];
            members[indexToRemove] = lastMember;
            members[indexToRemove].index = indexToRemove;
            addressToMember[lastMember.walletAddress].index = indexToRemove;
        }

        members.pop();
        delete addressToMember[msg.sender];
        emit MemberRemoved(msg.sender, removedName, removedAge);
    }

    // GAS OPTIMIZATION: Use string calldata parameter location to avoid copying string from calldata to memory
    function updateMember(string calldata _name, uint256 _age) public{
        // GAS OPTIMIZATION: Cache storage pointers for mapping and array elements to prevent redundant SLOADs
        Member storage senderMember = addressToMember[msg.sender];
        require(senderMember.isRegistered, "User is not registered!");
        uint256 memberIndex = senderMember.index;
        senderMember.name = _name;
        senderMember.age = _age;

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
