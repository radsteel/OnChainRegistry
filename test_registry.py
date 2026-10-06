import unittest
import solcx
from web3 import Web3

solcx.install_solc('0.8.18')

class TestRegistryContract(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        with open('OnChainRegistry.sol') as f:
            source = f.read()
        compiled = solcx.compile_source(source, output_values=['abi', 'bin'], solc_version='0.8.18')
        _, cls.contract_interface = list(compiled.items())[0]

    def setUp(self):
        self.w3 = Web3(Web3.EthereumTesterProvider())
        self.accounts = self.w3.eth.accounts
        Registry = self.w3.eth.contract(abi=self.contract_interface['abi'], bytecode=self.contract_interface['bin'])
        tx_hash = Registry.constructor().transact({'from': self.accounts[0]})
        tx_receipt = self.w3.eth.wait_for_transaction_receipt(tx_hash)
        self.registry = self.w3.eth.contract(address=tx_receipt.contractAddress, abi=self.contract_interface['abi'])

    def test_register_and_getters(self):
        tx = self.registry.functions.registerMember("Alice", 25).transact({'from': self.accounts[1]})
        self.w3.eth.wait_for_transaction_receipt(tx)

        self.assertTrue(self.registry.functions.isMemberRegistered(self.accounts[1]).call())
        self.assertEqual(self.registry.functions.getTotalMembers().call(), 1)

        # Member struct fields tuple order:
        # (walletAddress, isRegistered, age, index, name)
        m1 = self.registry.functions.getMember(self.accounts[1]).call()
        self.assertEqual(m1[0], self.accounts[1])
        self.assertEqual(m1[1], True)
        self.assertEqual(m1[2], 25)
        self.assertEqual(m1[3], 0)
        self.assertEqual(m1[4], "Alice")

        m_idx = self.registry.functions.getMemberByIndex(0).call()
        self.assertEqual(m_idx[4], "Alice")

        all_m = self.registry.functions.getAllMembers().call()
        self.assertEqual(len(all_m), 1)

    def test_register_duplicate_fails(self):
        self.registry.functions.registerMember("Alice", 25).transact({'from': self.accounts[1]})
        with self.assertRaises(Exception):
            self.registry.functions.registerMember("Alice Duplicate", 26).transact({'from': self.accounts[1]})

    def test_update_member(self):
        self.registry.functions.registerMember("Alice", 25).transact({'from': self.accounts[1]})
        self.registry.functions.updateMember("Alice Updated", 26).transact({'from': self.accounts[1]})

        m = self.registry.functions.getMember(self.accounts[1]).call()
        self.assertEqual(m[4], "Alice Updated")
        self.assertEqual(m[2], 26)

        m_idx = self.registry.functions.getMemberByIndex(0).call()
        self.assertEqual(m_idx[4], "Alice Updated")
        self.assertEqual(m_idx[2], 26)

    def test_remove_member_swap_and_pop(self):
        # Register 3 members
        self.registry.functions.registerMember("Alice", 25).transact({'from': self.accounts[1]})
        self.registry.functions.registerMember("Bob", 30).transact({'from': self.accounts[2]})
        self.registry.functions.registerMember("Charlie", 35).transact({'from': self.accounts[3]})

        self.assertEqual(self.registry.functions.getTotalMembers().call(), 3)

        # Remove Alice (index 0) -> Bob (1) stays, Charlie (2 -> now 0) swaps into index 0
        self.registry.functions.removeMember().transact({'from': self.accounts[1]})

        self.assertEqual(self.registry.functions.getTotalMembers().call(), 2)
        self.assertFalse(self.registry.functions.isMemberRegistered(self.accounts[1]).call())

        # Check Charlie is now at index 0
        charlie_in_map = self.registry.functions.getMember(self.accounts[3]).call()
        self.assertEqual(charlie_in_map[3], 0)

        charlie_in_arr = self.registry.functions.getMemberByIndex(0).call()
        self.assertEqual(charlie_in_arr[0], self.accounts[3])
        self.assertEqual(charlie_in_arr[4], "Charlie")
        self.assertEqual(charlie_in_arr[3], 0)

        # Check Bob is still at index 1
        bob_in_arr = self.registry.functions.getMemberByIndex(1).call()
        self.assertEqual(bob_in_arr[0], self.accounts[2])
        self.assertEqual(bob_in_arr[4], "Bob")

if __name__ == '__main__':
    unittest.main()
