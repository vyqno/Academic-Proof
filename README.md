# Academic Proof - Decentralized Academic Credentials System

A secure, blockchain-based system for issuing and verifying academic credentials as Soulbound NFTs. Built with Solidity and Foundry for tamper-proof, verifiable diplomas.

[![Tests](https://img.shields.io/badge/tests-64%20passing-brightgreen)]()
[![Solidity](https://img.shields.io/badge/solidity-0.8.28-blue)]()
[![License](https://img.shields.io/badge/license-MIT-blue)]()

## 🚀 Live Deployment - Sepolia Testnet

The system is deployed and verified on Sepolia testnet:

| Contract | Address | Etherscan |
|----------|---------|-----------|
| **UniversityRegistry** | `0x777cc9de0180ab4A98072C86cb67c7763906D6B1` | [View on Etherscan](https://sepolia.etherscan.io/address/0x777cc9de0180ab4A98072C86cb67c7763906D6B1) |
| **AcademicCredential** | `0x73F397Eb0eE3d849aa14fCa1Ecb4d0016f24C475` | [View on Etherscan](https://sepolia.etherscan.io/address/0x73F397Eb0eE3d849aa14fCa1Ecb4d0016f24C475) |
| **CredentialVerifier** | `0x98F3773D5fdc03a5821826C65e85E239bc5bEAaB` | [View on Etherscan](https://sepolia.etherscan.io/address/0x98F3773D5fdc03a5821826C65e85E239bc5bEAaB) |

**Deployment Stats:**
- **Network:** Sepolia Testnet (Chain ID: 11155111)
- **Block:** 9553024
- **Total Cost:** 0.0086 ETH (~$0.02 USD)
- **Gas Used:** 8,664,481 gas
- **Deployer:** `0x22fdF823E8E90cFAC1116cC6b6AD30010B3cf88B`

## Table of Contents

- [Live Deployment](#-live-deployment---sepolia-testnet)
- [Test Results](#-test-results)
- [Overview](#overview)
- [Features](#features)
- [Architecture](#architecture)
- [Smart Contracts](#smart-contracts)
- [Installation](#installation)
- [Usage](#usage)
- [Testing](#testing)
- [Deployment](#deployment)
- [Frontend Integration](#frontend-integration)
- [Security Considerations](#security-considerations)

## ✅ Test Results

Comprehensive test suite with 100% passing tests across all categories:

```
╭────────────────────────┬────────┬────────┬─────────╮
│ Test Suite             │ Passed │ Failed │ Skipped │
├════════════════════════┼════════┼════════┼═════════┤
│ IntegrationTest        │ 11     │ 0      │ 0       │
│ DeploymentTest         │ 3      │ 0      │ 0       │
│ AcademicCredentialTest │ 18     │ 0      │ 0       │
│ CredentialVerifierTest │ 14     │ 0      │ 0       │
│ UniversityRegistryTest │ 18     │ 0      │ 0       │
╰────────────────────────┴────────┴────────┴─────────╯

✅ Total: 64 tests passing | 0 failing | 0 skipped
```

**Test Coverage:**
- **Unit Tests** (50 tests): Individual contract functionality
- **Integration Tests** (11 tests): Complete user workflows
- **Staging Tests** (3 tests): Deployment verification

**Run tests:**
```bash
forge test          # Run all tests
forge test -vv      # With logs
make test-unit      # Unit tests only
make test-integration  # Integration tests only
make coverage       # Generate coverage report
```

## Overview

Academic Proof is a comprehensive solution for universities to issue tamper-proof academic credentials on the blockchain. The system uses Soulbound (non-transferable) NFTs to ensure credentials remain with the rightful owner and cannot be traded or sold.

### Key Benefits

- **Tamper-Proof**: Credentials stored on blockchain cannot be altered or forged
- **Instant Verification**: Employers can verify credentials in seconds
- **No Third-Party Required**: Direct verification without intermediaries
- **Multi-Signature Security**: Universities can require multiple approvers
- **Revocation Support**: Invalid credentials can be revoked when fraud is detected
- **Soulbound**: Credentials cannot be transferred, ensuring authenticity

## Features

### For Universities
- Register and manage university profiles on-chain
- Multi-signature approval system for credential issuance
- Add/remove authorized signers
- Issue credentials with detailed metadata (degree type, GPA, honors)
- Revoke fraudulent credentials
- Deactivation/reactivation capabilities

### For Students
- Receive Soulbound NFT credentials automatically
- Share credentials via QR codes
- Maintain verifiable academic history
- Credentials remain in wallet forever (non-transferable)

### For Verifiers (Employers/Institutions)
- Instant credential verification
- Batch verification support
- Check credential validity and revocation status
- View detailed credential information
- Verify specific degrees or majors

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   Academic Credentials System                │
└─────────────────────────────────────────────────────────────┘
                           │
         ┌─────────────────┼─────────────────┐
         │                 │                 │
         ▼                 ▼                 ▼
┌────────────────┐ ┌─────────────────┐ ┌──────────────────┐
│ University     │ │  Academic       │ │  Credential      │
│ Registry       │ │  Credential     │ │  Verifier        │
│                │ │  (Soulbound NFT)│ │                  │
└────────────────┘ └─────────────────┘ └──────────────────┘
         │                 │                 │
         │                 └─────────┬───────┘
         │                           │
         ▼                           ▼
┌────────────────┐          ┌─────────────────┐
│ Credential     │          │  View Functions │
│ Metadata       │          │  & Events       │
│ Library        │          │                 │
└────────────────┘          └─────────────────┘
```

## Smart Contracts

### Core Contracts

#### 1. UniversityRegistry.sol
Manages university registration and authorization.

**Key Functions:**
- `registerUniversity()` - Register a new university (owner only)
- `addSigner()` / `removeSigner()` - Manage authorized signers
- `updateRequiredSigners()` - Update signature requirements
- `deactivateUniversity()` / `reactivateUniversity()` - Control university status

#### 2. AcademicCredential.sol
Main soulbound NFT contract for academic credentials.

**Key Functions:**
- `requestCredential()` - Initiate credential issuance
- `signCredential()` - Add approval signature
- `revokeCredential()` - Revoke a credential
- `restoreCredential()` - Restore a revoked credential
- `getCredential()` - View credential details
- `getQRCodeData()` - Get QR code formatted data

**Features:**
- Soulbound (non-transferable) implementation
- Multi-signature approval workflow
- Automatic minting after sufficient signatures
- Duplicate prevention
- Rich metadata support

#### 3. CredentialVerifier.sol
Helper contract for credential verification.

**Key Functions:**
- `verifyCredential()` - Verify single credential
- `batchVerifyCredentials()` - Verify multiple credentials
- `getVerificationSummary()` - Get human-readable summary
- `hasValidDegree()` - Check if student has specific degree
- `verifyStudentCredentials()` - Get all credentials for a student

#### 4. CredentialMetadata.sol (Library)
Data structures and helper functions for credential metadata.

**Enums:**
- `DegreeType`: ASSOCIATE, BACHELOR, MASTER, DOCTORATE, CERTIFICATE, DIPLOMA
- `Honors`: NONE, CUM_LAUDE, MAGNA_CUM_LAUDE, SUMMA_CUM_LAUDE, WITH_DISTINCTION, WITH_HIGH_DISTINCTION

## Installation

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) installed
- Git

### Setup

```bash
# Clone the repository
git clone <your-repo-url>
cd Academic-Proof

# Install dependencies
forge install

# Build contracts
forge build
```

## Usage

### Running Tests

```bash
# Run all tests
forge test

# Run with verbosity
forge test -vv

# Run specific test
forge test --match-test testCompleteGraduationFlow -vvv

# Generate gas report
forge test --gas-report
```

All 61 tests pass successfully, covering:
- 18 UniversityRegistry tests
- 18 AcademicCredential tests
- 14 CredentialVerifier tests
- 11 Integration tests

### Code Coverage

```bash
forge coverage
```

## Deployment

### 1. Deploy All Contracts

Create a `.env` file:

```bash
PRIVATE_KEY=your_private_key_here
RPC_URL=your_rpc_url_here
```

Deploy:

```bash
source .env
forge script script/DeployAll.s.sol:DeployAll --rpc-url $RPC_URL --broadcast --verify
```

Save the deployed addresses from the output.

### 2. Register a University

```bash
# Set environment variables
export REGISTRY_ADDRESS=<deployed_registry_address>
export UNI_ADMIN=<university_admin_address>
export UNI_NAME="Massachusetts Institute of Technology"
export UNI_COUNTRY="USA"
export UNI_METADATA_URI="ipfs://QmXXXXX..."
export SIGNERS="0x123...,0x456...,0x789..."
export REQUIRED_SIGNERS=2

# Run script
forge script script/RegisterUniversity.s.sol:RegisterUniversity --rpc-url $RPC_URL --broadcast
```

### 3. Issue a Credential

```bash
# Set environment variables
export CREDENTIAL_ADDRESS=<deployed_credential_address>
export STUDENT_ADDRESS=<student_wallet_address>
export UNIVERSITY_ID=1
export DEGREE_TYPE=1  # 0=ASSOCIATE, 1=BACHELOR, 2=MASTER, 3=DOCTORATE, 4=CERTIFICATE, 5=DIPLOMA
export MAJOR="Computer Science"
export GPA=385  # 3.85 GPA (multiply by 100)
export HONORS=2  # 0=NONE, 1=CUM_LAUDE, 2=MAGNA_CUM_LAUDE, 3=SUMMA_CUM_LAUDE, etc.
export GRADUATION_DATE=1704067200  # Unix timestamp
export METADATA_URI="ipfs://QmYYYYY..."

# Request credential (first signer)
forge script script/IssueCredential.s.sol:IssueCredential --rpc-url $RPC_URL --broadcast
```

### 4. Sign Credential (Additional Signers)

```bash
export CREDENTIAL_ID=1  # From previous step

# Sign with second signer's private key
forge script script/SignCredential.s.sol:SignCredential --rpc-url $RPC_URL --broadcast
```

### 5. Verify a Credential

```bash
export VERIFIER_ADDRESS=<deployed_verifier_address>
export CREDENTIAL_ID=1

# Verify credential
forge script script/VerifyCredential.s.sol:VerifyCredential --rpc-url $RPC_URL
```

## Frontend Integration

### Events for Frontend Listening

All major actions emit events:

```solidity
// University Registry Events
event UniversityRegistered(uint256 indexed universityId, address indexed admin, string name);
event UniversityDeactivated(uint256 indexed universityId);
event SignerAdded(uint256 indexed universityId, address indexed signer);

// Academic Credential Events
event CredentialRequested(uint256 indexed credentialId, address indexed student, uint256 indexed universityId);
event CredentialSigned(uint256 indexed credentialId, address indexed signer, uint256 signatureCount);
event CredentialIssued(uint256 indexed credentialId, address indexed student, uint256 indexed universityId, DegreeType degreeType);
event CredentialRevoked(uint256 indexed credentialId, string reason);

// Verifier Events
event CredentialVerified(uint256 indexed credentialId, address indexed verifier, bool isValid);
```

### View Functions for UI

```javascript
// Get university info
const university = await universityRegistry.getUniversity(universityId);

// Get credential details
const credential = await academicCredential.getCredential(credentialId);

// Get student's credentials
const studentCreds = await academicCredential.getStudentCredentials(studentAddress);

// Verify credential
const result = await credentialVerifier.verifyCredential(credentialId);

// Get QR code data
const qrData = await academicCredential.getQRCodeData(credentialId);

// Batch verify
const results = await credentialVerifier.batchVerifyCredentials([id1, id2, id3]);
```

### IPFS Metadata Structure

Recommended JSON structure for credential metadata:

```json
{
  "name": "Bachelor of Science in Computer Science",
  "description": "Degree awarded by Massachusetts Institute of Technology",
  "image": "ipfs://QmXXXX...",
  "attributes": [
    {
      "trait_type": "University",
      "value": "MIT"
    },
    {
      "trait_type": "Degree Type",
      "value": "Bachelor"
    },
    {
      "trait_type": "Major",
      "value": "Computer Science"
    },
    {
      "trait_type": "GPA",
      "value": "3.85"
    },
    {
      "trait_type": "Honors",
      "value": "Magna Cum Laude"
    },
    {
      "trait_type": "Graduation Year",
      "value": "2024"
    }
  ]
}
```

## Security Considerations

### Implemented Security Features

1. **Access Control**
   - Only registered universities can issue credentials
   - Only authorized signers can approve credentials
   - Only university admin can manage signers
   - Only contract owner can register universities

2. **Soulbound Implementation**
   - Credentials cannot be transferred after minting
   - Override of ERC721 `_update` function prevents transfers
   - Credentials remain with student forever

3. **Multi-Signature Approval**
   - Configurable number of required signatures
   - Prevents single point of failure
   - Duplicate signature prevention

4. **Input Validation**
   - GPA range validation (0-4.00)
   - Graduation date validation (not in future)
   - Major string validation
   - Address validation

5. **Duplicate Prevention**
   - Hash-based duplicate credential detection
   - Prevents issuing same credential twice

6. **Revocation System**
   - Credentials can be revoked when fraud detected
   - Revoked credentials fail verification
   - Restoration capability for false positives

### Best Practices for Universities

1. Use hardware wallets for signer keys
2. Implement off-chain approval workflows before blockchain submission
3. Store credential metadata on IPFS or similar decentralized storage
4. Regularly audit authorized signers list
5. Implement multi-signature wallets for university admin role
6. Keep backup of all credential IDs and student mappings

### Audit Recommendations

Before mainnet deployment:
- [ ] Professional security audit
- [ ] Gas optimization review
- [ ] Formal verification of critical functions
- [ ] Penetration testing
- [ ] Economic attack vector analysis

## Project Structure

```
Academic-Proof/
├── src/
│   ├── AcademicCredential.sol      # Main soulbound NFT contract
│   ├── UniversityRegistry.sol      # University management
│   ├── CredentialVerifier.sol      # Verification helper
│   └── libraries/
│       └── CredentialMetadata.sol  # Metadata structures
├── script/
│   ├── DeployAll.s.sol            # Deploy all contracts
│   ├── RegisterUniversity.s.sol   # Register university
│   ├── IssueCredential.s.sol      # Issue credential
│   ├── SignCredential.s.sol       # Sign credential
│   └── VerifyCredential.s.sol     # Verify credential
├── test/
│   ├── UniversityRegistry.t.sol   # Registry tests (18 tests)
│   ├── AcademicCredential.t.sol   # Credential tests (18 tests)
│   ├── CredentialVerifier.t.sol   # Verifier tests (14 tests)
│   └── Integration.t.sol          # Integration tests (11 tests)
├── foundry.toml                    # Foundry configuration
└── README.md                       # This file
```

## Gas Optimization

The contracts are optimized for gas efficiency:
- Use of immutable variables where possible
- Efficient storage packing
- Minimal external calls
- Event-driven architecture for off-chain data
- Batch operations support

## Future Enhancements

Potential improvements for future versions:
- [ ] Upgradeable proxy pattern
- [ ] Cross-chain credential verification
- [ ] Decentralized university governance (DAO)
- [ ] Credential expiration dates
- [ ] Course-level granularity
- [ ] Student privacy features (zero-knowledge proofs)
- [ ] Credential templates
- [ ] Bulk issuance optimization

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Write tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

MIT License - see LICENSE file for details

## Support

For questions or support:
- Open an issue on GitHub
- Contact: [your-contact-info]

## Acknowledgments

Built with:
- [Foundry](https://github.com/foundry-rs/foundry) - Ethereum development toolkit
- [OpenZeppelin](https://github.com/OpenZeppelin/openzeppelin-contracts) - Secure contract libraries
- [Solidity](https://soliditylang.org/) - Smart contract language

---

**Disclaimer**: This is a demonstration project. Conduct thorough audits before using in production.
