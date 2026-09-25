import unittest
import solcx
from web3 import Web3

class TestRegistryContract(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        solcx.install_solc('0.8.18')
        solcx.set_solc_version('0.8.18')
        cls.compiled = solcx.compile_files(['OnChainRegistry.sol'], solc_version='0.8.18')
        key = [k for k in cls.compiled.keys() if k.endswith(':Registry')][0]
        cls.abi = cls.compiled[key]['abi']
        cls.bytecode = cls.compiled[key]['bin']

    def setUp(self):
        self.w3 = Web3(Web3.EthereumTesterProvider())
        self.accounts = self.w3.eth.accounts
        RegistryContract = self.w3.eth.contract(abi=self.abi, bytecode=self.bytecode)
        tx_hash = RegistryContract.constructor().transact({'from': self.accounts[0]})
        tx_receipt = self.w3.eth.wait_for_transaction_receipt(tx_hash)
        self.contract = self.w3.eth.contract(address=tx_receipt.contractAddress, abi=self.abi)

    def test_register_member(self):
        acc = self.accounts[0]
        tx_hash = self.contract.functions.registerMember("Alice", 25).transact({'from': acc})
        receipt = self.w3.eth.wait_for_transaction_receipt(tx_hash)

        self.assertTrue(self.contract.functions.isMemberRegistered(acc).call())
        member = self.contract.functions.getMember(acc).call()
        self.assertEqual(member[0], acc) # walletAddress
        self.assertEqual(member[1], "Alice") # name
        self.assertEqual(member[2], 25) # age
        self.assertEqual(member[3], 0) # index
        self.assertTrue(member[4]) # isRegistered
        self.assertEqual(self.contract.functions.getTotalMembers().call(), 1)

    def test_register_duplicate_reverts(self):
        acc = self.accounts[0]
        self.contract.functions.registerMember("Alice", 25).transact({'from': acc})
        with self.assertRaises(Exception):
            self.contract.functions.registerMember("Alice", 25).transact({'from': acc})

    def test_update_member(self):
        acc = self.accounts[0]
        self.contract.functions.registerMember("Alice", 25).transact({'from': acc})

        tx_hash = self.contract.functions.updateMember("Alice Updated", 26).transact({'from': acc})
        self.w3.eth.wait_for_transaction_receipt(tx_hash)

        member = self.contract.functions.getMember(acc).call()
        self.assertEqual(member[1], "Alice Updated")
        self.assertEqual(member[2], 26)

        member_by_idx = self.contract.functions.getMemberByIndex(0).call()
        self.assertEqual(member_by_idx[1], "Alice Updated")
        self.assertEqual(member_by_idx[2], 26)

    def test_remove_member_swap_and_pop(self):
        acc1 = self.accounts[0]
        acc2 = self.accounts[1]
        acc3 = self.accounts[2]

        self.contract.functions.registerMember("Alice", 25).transact({'from': acc1})
        self.contract.functions.registerMember("Bob", 30).transact({'from': acc2})
        self.contract.functions.registerMember("Charlie", 35).transact({'from': acc3})

        self.assertEqual(self.contract.functions.getTotalMembers().call(), 3)

        # Remove Bob (middle element, index 1)
        tx_hash = self.contract.functions.removeMember().transact({'from': acc2})
        receipt = self.w3.eth.wait_for_transaction_receipt(tx_hash)

        self.assertEqual(self.contract.functions.getTotalMembers().call(), 2)
        self.assertFalse(self.contract.functions.isMemberRegistered(acc2).call())

        # Charlie should have been swapped to index 1
        charlie_member = self.contract.functions.getMember(acc3).call()
        self.assertEqual(charlie_member[3], 1)

        charlie_by_idx = self.contract.functions.getMemberByIndex(1).call()
        self.assertEqual(charlie_by_idx[0], acc3)
        self.assertEqual(charlie_by_idx[1], "Charlie")

    def test_get_all_members(self):
        acc1 = self.accounts[0]
        acc2 = self.accounts[1]
        self.contract.functions.registerMember("Alice", 25).transact({'from': acc1})
        self.contract.functions.registerMember("Bob", 30).transact({'from': acc2})

        all_members = self.contract.functions.getAllMembers().call()
        self.assertEqual(len(all_members), 2)
        self.assertEqual(all_members[0][1], "Alice")
        self.assertEqual(all_members[1][1], "Bob")

if __name__ == '__main__':
    unittest.main()
