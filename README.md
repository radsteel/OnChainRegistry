# 🔗 OnChainRegistry
> A Decentralized, Gas-Optimized Identity & Member Management System on Ethereum
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Solidity](https://img.shields.io/badge/Solidity-%5E0.8.18-363636?logo=solidity)](https://soliditylang.org/)
[![EVM](https://img.shields.io/badge/EVM-Compatible-627EEA?logo=ethereum)](https://ethereum.org/)
---
> [!NOTE]
> Built as a core milestone project demonstrating state synchronization, EVM gas optimization using the **Swap & Pop** deletion pattern, and event emission in Solidity. Designed as a part of foundational Web3 portofilo for professional growth.
---
## ✨ Features
- 🆔 On-Chain Registration: Uses msg.sender for secure, tamper-proof user profile registration.
- ⚡ Gas-Optimized Deletion: Implements the Swap and Pop pattern to remove members in $O(1)$ constant time complexity.
- 🔄 Real-Time State Sync: Keeps dynamic arrays (members[]) and lookup mappings (addressToMember) perfectly synchronized.
- 📢 Off-Chain Indexing (Events): Emits MemberRegistered, MemberUpdated, and MemberRemoved events for frontend listeners and indexers.
- 🔒 Access Control & Safety: Prevents duplicate registrations and out-of-bounds array access via strict require() guards.
- 📊 Read-Only Inspection: Built-in view helper functions (getAllMembers, getMemberByIndex, isMemberRegistered).
---
## 🏗️ Smart Contract Architecture
### Data Structure (Member Struct)

| Field | Type | Description |
| :--- | :--- | :--- |
| walletAddress | address | Member's Ethereum wallet address (msg.sender) |
| name | string | Registered display name |
| age | uint256 | Registered age |
| index | uint256 | Member's current position in the dynamic array |
| isRegistered | bool | Registration status flag |

### Core Functions
- 🟢 registerMember(string _name, uint256 _age) — Registers caller address.
- 🔵 updateMember(string _name, uint256 _age) — Updates caller profile details.
- 🔴 removeMember() — Deletes caller profile using $O(1)$ Swap & Pop logic.
- 🔍 getMember(address) / getMemberByIndex(uint256) / getAllMembers() — view functions for data retrieval.
---
## 💡 Technical Highlight: Swap & Pop Pattern
> [!TIP]
> Why Swap & Pop?  
> In Solidity, removing an element from the middle of a dynamic array usually requires shifting all subsequent elements ($O(n)$ complexity and high gas cost).  
> By swapping the element to be deleted with the last element of the array and then executing .pop(), we achieve $O(1)$ constant gas efficiency without leaving storage gaps.
---
## 🚀 Quick Start (Remix IDE)
1. Open [Remix IDE](https://remix.ethereum.org/).
2. Create a new file named OnChainRegistry.sol and paste the contract code.
3. Select Solidity compiler version 0.8.18 or higher.
4. Deploy using Injected Provider (MetaMask) or Remix VM.
### 💻 Code Example Usage
solidity
// 1. Register a new member profile
registerMember("Radmehr", 18);
// 2. Query registration status
isMemberRegistered(msg.sender); // Returns: true
// 3. Update profile details
updateMember("Radmehr", 19);
// 4. Safely remove profile from storage
removeMember();

---
## 📄 License
This project is licensed under the [MIT License](LICENSE).
---
<p align="center">
  Developed with ❤️ for Web3 & Smart Contract Engineering
</p>
