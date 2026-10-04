import solcx
from web3 import Web3

solcx.install_solc('0.8.18')

code_v0 = """//SPDX-License-Identifier: MIT
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
        require (!addressToMember[msg.sender].isRegistered, "User is already registered!");
        uint256 newIndex = members.length;
        Member memory newMember = Member(msg.sender, _name, _age, newIndex, true);
        members.push(newMember);
        addressToMember[msg.sender] = newMember;
        emit MemberRegistered(msg.sender, _name, _age);
    }
    function removeMember() public{
        require(addressToMember[msg.sender].isRegistered, "User is not registered!");
        uint256 indexToRemove = addressToMember[msg.sender].index;
        uint256 lastIndex = members.length - 1;
        if(indexToRemove != lastIndex){
            Member memory lastMember = members[lastIndex];
            members[indexToRemove] = lastMember;
            members[indexToRemove].index = indexToRemove;
            addressToMember[lastMember.walletAddress].index = indexToRemove;
        }
        string memory removedName = addressToMember[msg.sender].name;
        uint256 removedAge = addressToMember[msg.sender].age;
        members.pop();
        delete addressToMember[msg.sender];
        emit MemberRemoved(msg.sender, removedName, removedAge);
    }
    function updateMember(string memory _name, uint256 _age) public{
        require(addressToMember[msg.sender].isRegistered, "User is not registered!");
        uint256 memberIndex = addressToMember[msg.sender].index;
        addressToMember[msg.sender].name = _name;
        addressToMember[msg.sender].age = _age;
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
"""

code_v1 = """//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Registry{
    // Optimization: Struct field packing groups walletAddress (20 bytes) and isRegistered (1 byte)
    // into a single 32-byte EVM storage slot, reducing struct footprint from 5 slots to 4 slots.
    struct Member {
        address walletAddress;
        bool isRegistered;
        uint256 age;
        uint256 index;
        string name;
    }
    Member[] public members;
    mapping(address => Member) public addressToMember;

    event MemberRegistered(address indexed walletAddress, string name, uint256 age);
    event MemberRemoved(address indexed walletAddress, string name, uint256 age);
    event MemberUpdated(address indexed walletAddress, string name, uint256 age);

    function registerMember(string calldata _name, uint256 _age) public{
        require (!addressToMember[msg.sender].isRegistered, "User is already registered!");
        uint256 newIndex = members.length;
        Member memory newMember = Member(msg.sender, true, _age, newIndex, _name);
        members.push(newMember);
        addressToMember[msg.sender] = newMember;
        emit MemberRegistered(msg.sender, _name, _age);
    }
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
    function updateMember(string calldata _name, uint256 _age) public{
        Member storage member = addressToMember[msg.sender];
        require(member.isRegistered, "User is not registered!");
        uint256 memberIndex = member.index;
        member.name = _name;
        member.age = _age;
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
"""

def run_test(source, label):
    compiled = solcx.compile_source(source, output_values=['abi', 'bin'], solc_version='0.8.18')
    _, contract_interface = list(compiled.items())[0]
    w3 = Web3(Web3.EthereumTesterProvider())
    accounts = w3.eth.accounts

    Registry = w3.eth.contract(abi=contract_interface['abi'], bytecode=contract_interface['bin'])
    tx_hash = Registry.constructor().transact({'from': accounts[0]})
    tx_receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
    registry = w3.eth.contract(address=tx_receipt.contractAddress, abi=contract_interface['abi'])

    r1 = w3.eth.wait_for_transaction_receipt(registry.functions.registerMember("Alice", 25).transact({'from': accounts[1]}))
    r2 = w3.eth.wait_for_transaction_receipt(registry.functions.registerMember("Bob", 30).transact({'from': accounts[2]}))
    r3 = w3.eth.wait_for_transaction_receipt(registry.functions.registerMember("Charlie", 35).transact({'from': accounts[3]}))

    up = w3.eth.wait_for_transaction_receipt(registry.functions.updateMember("Alice Updated", 26).transact({'from': accounts[1]}))

    rem = w3.eth.wait_for_transaction_receipt(registry.functions.removeMember().transact({'from': accounts[1]}))

    print(f"--- {label} ---")
    print("Deploy Gas:", tx_receipt.gasUsed)
    print("Register Member 1 Gas:", r1.gasUsed)
    print("Register Member 2 Gas:", r2.gasUsed)
    print("Register Member 3 Gas:", r3.gasUsed)
    print("Update Member Gas:", up.gasUsed)
    print("Remove Member Gas:", rem.gasUsed)

run_test(code_v0, "v0 Original")
run_test(code_v1, "v1 Optimized (Calldata + Storage Pointers + Struct Packing)")
