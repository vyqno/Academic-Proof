# Deployment Guide - Academic Proof

This guide covers deploying and interacting with the Academic Proof system on both Anvil (local) and Sepolia testnet.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Setup](#setup)
- [Deployment](#deployment)
- [Interactions](#interactions)
- [Testing](#testing)
- [Makefile Commands](#makefile-commands)

## Prerequisites

- Foundry installed
- Environment variables configured
- Wallet with testnet ETH (for Sepolia)

## Setup

### 1. Install Dependencies

```bash
make install
```

This installs:
- foundry-devops (for deployment management)
- OpenZeppelin contracts
- Forge-std

### 2. Configure Environment

Copy the example environment file:

```bash
cp .env.example .env
```

Edit `.env` with your configuration:

```bash
# For Sepolia deployment
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY
PRIVATE_KEY=your_private_key_here
ETHERSCAN_API_KEY=your_etherscan_api_key

# For Anvil (local testing)
ANVIL_RPC_URL=http://127.0.0.1:8545
```

## Deployment

### Deploy to Anvil (Local)

1. Start Anvil in a separate terminal:

```bash
make anvil
```

2. Deploy contracts:

```bash
make deploy-anvil
```

Output will show:
```
========================================
DEPLOYING TO: Anvil Local
Chain ID: 31337
========================================
UniversityRegistry:     0x...
AcademicCredential:     0x...
CredentialVerifier:     0x...
```

### Deploy to Sepolia

```bash
make deploy-sepolia
```

This will:
- Deploy all contracts
- Verify on Etherscan
- Save deployment addresses

## Interactions

The system provides interaction scripts for common operations using foundry-devops for automatic address discovery.

### 1. Register a University

Set environment variables in `.env`:

```bash
UNI_ADMIN=0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb
UNI_NAME=Massachusetts Institute of Technology
UNI_COUNTRY=USA
UNI_METADATA_URI=ipfs://QmXXXXX...
SIGNER_1=0x...
SIGNER_2=0x...
REQUIRED_SIGNERS=2
```

Run:

```bash
# On Anvil
make register-university-anvil

# On Sepolia
make register-university-sepolia
```

### 2. Issue a Credential

Set environment variables:

```bash
STUDENT_ADDRESS=0x...
UNIVERSITY_ID=1
DEGREE_TYPE=1  # 1=BACHELOR
MAJOR=Computer Science
GPA=385  # 3.85
HONORS=2  # 2=MAGNA_CUM_LAUDE
GRADUATION_DATE=1704067200
METADATA_URI=ipfs://QmYYYYY...
```

Run:

```bash
# On Anvil
make issue-credential-anvil

# On Sepolia
make issue-credential-sepolia
```

### 3. Sign a Credential

For multi-signature universities, additional signers must approve:

```bash
CREDENTIAL_ID=1

# On Anvil
make sign-credential-anvil

# On Sepolia (use signer's private key)
PRIVATE_KEY=signer_private_key make sign-credential-sepolia
```

### 4. Verify a Credential

```bash
CREDENTIAL_ID=1

# On Anvil
make verify-credential-anvil

# On Sepolia
make verify-credential-sepolia
```

Output shows:
```
========================================
VERIFICATION RESULT
========================================
Valid: true
Issued: true
Revoked: false

Student: 0x...
University: MIT
Major: Computer Science
GPA: 385
========================================

Summary: VALID: Bachelor in Computer Science from MIT
```

### 5. Revoke a Credential

```bash
CREDENTIAL_ID=1
REVOKE_REASON=Academic misconduct detected

# On Anvil
make revoke-credential-anvil

# On Sepolia
make revoke-credential-sepolia
```

### 6. Get Student Credentials

```bash
STUDENT_ADDRESS=0x...

# On Anvil
make student-credentials-anvil

# On Sepolia
make student-credentials-sepolia
```

## Testing

### Run All Tests

```bash
make test
```

### Run Specific Test Suites

```bash
# Unit tests only
make test-unit

# Integration tests only
make test-integration

# Staging tests (fork tests)
make test-staging
```

### Generate Coverage Report

```bash
make coverage
```

### Gas Snapshots

```bash
make snapshot
```

## Makefile Commands

### Build & Development

```bash
make build          # Compile contracts
make clean          # Clean build artifacts
make format         # Format code
make lint           # Check code formatting
```

### Testing

```bash
make test                   # Run all tests
make test-unit             # Run unit tests
make test-integration      # Run integration tests
make test-staging          # Run staging/fork tests
make test-contract         # Test specific contract (interactive)
make test-function         # Test specific function (interactive)
make coverage              # Generate coverage report
make snapshot              # Generate gas snapshots
```

### Deployment

```bash
make deploy-anvil          # Deploy to local Anvil
make deploy-sepolia        # Deploy to Sepolia testnet
make check-deployments     # Check deployment addresses
```

### Interactions - Anvil

```bash
make register-university-anvil
make issue-credential-anvil
make sign-credential-anvil
make verify-credential-anvil
make student-credentials-anvil
make revoke-credential-anvil
```

### Interactions - Sepolia

```bash
make register-university-sepolia
make issue-credential-sepolia
make sign-credential-sepolia
make verify-credential-sepolia
make student-credentials-sepolia
make revoke-credential-sepolia
```

### Utilities

```bash
make flatten               # Flatten contracts
make gas-estimate          # Estimate deployment gas
make inspect-storage       # View storage layout
make contract-size         # Check contract sizes
make anvil                 # Start local Anvil node
```

## Complete Example Workflow

### Local Development (Anvil)

```bash
# 1. Start Anvil
make anvil

# 2. In another terminal, deploy
make deploy-anvil

# 3. Configure .env with addresses and parameters

# 4. Register a university
make register-university-anvil

# 5. Issue a credential
make issue-credential-anvil

# 6. Sign the credential (if multi-sig)
make sign-credential-anvil

# 7. Verify the credential
make verify-credential-anvil
```

### Testnet Deployment (Sepolia)

```bash
# 1. Configure .env with Sepolia RPC and private key

# 2. Deploy contracts
make deploy-sepolia

# 3. Update .env with deployed addresses

# 4. Register university
make register-university-sepolia

# 5. Issue credential
make issue-credential-sepolia

# 6. Verify credential
make verify-credential-sepolia
```

## Troubleshooting

### Contract Not Found

If interaction scripts can't find contracts:

```bash
# Check deployments
make check-deployments

# Manually set addresses in .env
REGISTRY_ADDRESS=0x...
CREDENTIAL_ADDRESS=0x...
VERIFIER_ADDRESS=0x...
```

### Transaction Reverts

Common issues:
- Insufficient gas/funds
- Not an authorized signer
- University not active
- Invalid parameters (GPA, dates, etc.)

Check transaction details on block explorer.

### Environment Variables

Make sure all required variables are set:

```bash
# Check if variable is set
echo $VARIABLE_NAME

# Set variable
export VARIABLE_NAME=value
```

## Advanced Usage

### Fork Testing

Test against Sepolia fork:

```bash
make fork-test-sepolia
```

### Custom Deployment

Run deployment script directly:

```bash
forge script script/DeploySystem.s.sol:DeploySystem \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY \
    --broadcast \
    --verify
```

### Manual Interaction

Use cast commands for manual interactions:

```bash
# Read function
cast call $REGISTRY_ADDRESS "getUniversityCount()(uint256)" \
    --rpc-url $RPC_URL

# Write function
cast send $REGISTRY_ADDRESS "registerUniversity(...)" \
    --private-key $PRIVATE_KEY \
    --rpc-url $RPC_URL
```

## Security Reminders

- Never commit real private keys
- Use hardware wallets for mainnet
- Test thoroughly on testnet first
- Verify contracts on Etherscan
- Use multi-signature wallets for admin functions
- Keep backup of all credential data

## Support

For issues or questions:
- Check the [main README](README.md)
- Open an issue on GitHub
- Review test files for examples

---

Built with Foundry & foundry-devops for professional-grade deployment.
