import unittest
from solcx import compile_files, install_solc
from web3 import Web3
from web3.providers.eth_tester import EthereumTesterProvider
from eth_tester.exceptions import TransactionFailed

class TestOnChainRegistry(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        install_solc("0.8.18")
        compiled = compile_files(["OnChainRegistry.sol"], solc_version="0.8.18")
        contract_key = [k for k in compiled.keys() if "Registry" in k][0]
        cls.abi = compiled[contract_key]['abi']
        cls.bytecode = compiled[contract_key]['bin']

    def setUp(self):
        self.w3 = Web3(EthereumTesterProvider())
        self.accounts = self.w3.eth.accounts
        Registry = self.w3.eth.contract(abi=self.abi, bytecode=self.bytecode)
        tx_hash = Registry.constructor().transact({'from': self.accounts[0]})
        tx_receipt = self.w3.eth.wait_for_transaction_receipt(tx_hash)
        self.contract = self.w3.eth.contract(address=tx_receipt.contractAddress, abi=self.abi)

    def test_register_member(self):
        acc = self.accounts[0]
        self.assertFalse(self.contract.functions.isMemberRegistered(acc).call())

        self.contract.functions.registerMember("Alice", 28).transact({'from': acc})

        self.assertTrue(self.contract.functions.isMemberRegistered(acc).call())
        self.assertEqual(self.contract.functions.getTotalMembers().call(), 1)

        member = self.contract.functions.getMember(acc).call()
        self.assertEqual(member[0], acc) # walletAddress
        self.assertEqual(member[1], "Alice") # name
        self.assertEqual(member[2], 28) # age
        self.assertEqual(member[3], 0) # index
        self.assertTrue(member[4]) # isRegistered

    def test_duplicate_register_reverts(self):
        acc = self.accounts[0]
        self.contract.functions.registerMember("Alice", 28).transact({'from': acc})
        with self.assertRaises((TransactionFailed, Exception)):
            self.contract.functions.registerMember("Alice Again", 29).transact({'from': acc})

    def test_update_member(self):
        acc = self.accounts[0]
        self.contract.functions.registerMember("Alice", 28).transact({'from': acc})
        self.contract.functions.updateMember("Alice Updated", 29).transact({'from': acc})

        member = self.contract.functions.getMember(acc).call()
        self.assertEqual(member[1], "Alice Updated")
        self.assertEqual(member[2], 29)

        member_by_idx = self.contract.functions.getMemberByIndex(0).call()
        self.assertEqual(member_by_idx[1], "Alice Updated")
        self.assertEqual(member_by_idx[2], 29)

    def test_update_unregistered_reverts(self):
        acc = self.accounts[0]
        with self.assertRaises((TransactionFailed, Exception)):
            self.contract.functions.updateMember("Nobody", 100).transact({'from': acc})

    def test_remove_member_swap_and_pop(self):
        acc0 = self.accounts[0]
        acc1 = self.accounts[1]
        acc2 = self.accounts[2]

        self.contract.functions.registerMember("Alice", 20).transact({'from': acc0})
        self.contract.functions.registerMember("Bob", 25).transact({'from': acc1})
        self.contract.functions.registerMember("Charlie", 30).transact({'from': acc2})

        self.assertEqual(self.contract.functions.getTotalMembers().call(), 3)

        # Remove middle member (Bob at index 1)
        self.contract.functions.removeMember().transact({'from': acc1})

        self.assertEqual(self.contract.functions.getTotalMembers().call(), 2)
        self.assertFalse(self.contract.functions.isMemberRegistered(acc1).call())

        # Charlie should have swapped into index 1
        charlie_member = self.contract.functions.getMember(acc2).call()
        self.assertEqual(charlie_member[3], 1)

        charlie_at_idx1 = self.contract.functions.getMemberByIndex(1).call()
        self.assertEqual(charlie_at_idx1[0], acc2)
        self.assertEqual(charlie_at_idx1[1], "Charlie")

    def test_remove_unregistered_reverts(self):
        acc = self.accounts[0]
        with self.assertRaises((TransactionFailed, Exception)):
            self.contract.functions.removeMember().transact({'from': acc})

    def test_get_all_members(self):
        self.contract.functions.registerMember("Alice", 20).transact({'from': self.accounts[0]})
        self.contract.functions.registerMember("Bob", 25).transact({'from': self.accounts[1]})
        all_members = self.contract.functions.getAllMembers().call()
        self.assertEqual(len(all_members), 2)
        self.assertEqual(all_members[0][1], "Alice")
        self.assertEqual(all_members[1][1], "Bob")

if __name__ == "__main__":
    unittest.main()
