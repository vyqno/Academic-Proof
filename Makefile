.PHONY: all test clean deploy install update build format anvil help

# Load environment variables
-include .env

# Default target
all: clean remove install update build

# Help
help:
	@echo "Usage:"
	@echo "  make deploy-anvil              - Deploy to Anvil local network"
	@echo "  make deploy-sepolia            - Deploy to Sepolia testnet"
	@echo "  make test                      - Run all tests"
	@echo "  make test-unit                 - Run unit tests only"
	@echo "  make test-integration          - Run integration tests only"
	@echo "  make test-staging              - Run staging tests (fork tests)"
	@echo "  make snapshot                  - Generate gas snapshots"
	@echo "  make coverage                  - Generate coverage report"
	@echo "  make format                    - Format code with forge fmt"
	@echo "  make anvil                     - Start local Anvil node"
	@echo "  make install                   - Install dependencies"
	@echo "  make update                    - Update dependencies"
	@echo "  make build                     - Build contracts"
	@echo "  make clean                     - Clean build artifacts"
	@echo ""
	@echo "Interaction Commands:"
	@echo "  make register-university       - Register a university"
	@echo "  make issue-credential          - Issue a credential"
	@echo "  make sign-credential           - Sign a credential"
	@echo "  make verify-credential         - Verify a credential"
	@echo "  make student-credentials       - Get student credentials"
	@echo "  make revoke-credential         - Revoke a credential"

# Install dependencies
install:
	forge install cyfrin/foundry-devops@0.2.2 --no-commit
	forge install OpenZeppelin/openzeppelin-contracts@v5.0.0 --no-commit
	forge install foundry-rs/forge-std@v1.9.4 --no-commit

# Update dependencies
update:
	forge update

# Build contracts
build:
	forge build

# Clean build artifacts
clean:
	forge clean

# Remove modules
remove:
	rm -rf lib

# Format code
format:
	forge fmt

# Start Anvil local node
anvil:
	anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1

# ================================================================
# TESTING
# ================================================================

# Run all tests
test:
	forge test -vvv

# Run unit tests
test-unit:
	forge test --match-path test/unit/* -vvv

# Run integration tests
test-integration:
	forge test --match-path test/integration/* -vvv

# Run staging tests (fork tests)
test-staging:
	@echo "Running staging tests on Sepolia fork..."
	forge test --match-path test/staging/* --fork-url $(SEPOLIA_RPC_URL) -vvv

# Generate gas snapshot
snapshot:
	forge snapshot

# Generate coverage report
coverage:
	forge coverage --report lcov
	@echo "Coverage report generated in lcov.info"

# Detailed coverage with summary
coverage-report:
	forge coverage --report summary

# ================================================================
# DEPLOYMENT
# ================================================================

# Deploy to Anvil
deploy-anvil:
	@echo "Deploying to Anvil..."
	forge script script/DeploySystem.s.sol:DeploySystem --rpc-url $(ANVIL_RPC_URL) --broadcast -vvvv

# Deploy to Sepolia
deploy-sepolia:
	@echo "Deploying to Sepolia..."
	forge script script/DeploySystem.s.sol:DeploySystem \
		--rpc-url $(SEPOLIA_RPC_URL) \
		--private-key $(PRIVATE_KEY) \
		--broadcast \
		--verify \
		--etherscan-api-key $(ETHERSCAN_API_KEY) \
		-vvvv

# ================================================================
# INTERACTIONS
# ================================================================

# Register University on Anvil
register-university-anvil:
	@echo "Registering university on Anvil..."
	forge script script/interactions/Interactions.s.sol:RegisterUniversityInteraction \
		--rpc-url $(ANVIL_RPC_URL) \
		--broadcast \
		-vvv

# Register University on Sepolia
register-university-sepolia:
	@echo "Registering university on Sepolia..."
	forge script script/interactions/Interactions.s.sol:RegisterUniversityInteraction \
		--rpc-url $(SEPOLIA_RPC_URL) \
		--private-key $(PRIVATE_KEY) \
		--broadcast \
		-vvv

# Issue Credential on Anvil
issue-credential-anvil:
	@echo "Issuing credential on Anvil..."
	forge script script/interactions/Interactions.s.sol:IssueCredentialInteraction \
		--rpc-url $(ANVIL_RPC_URL) \
		--broadcast \
		-vvv

# Issue Credential on Sepolia
issue-credential-sepolia:
	@echo "Issuing credential on Sepolia..."
	forge script script/interactions/Interactions.s.sol:IssueCredentialInteraction \
		--rpc-url $(SEPOLIA_RPC_URL) \
		--private-key $(PRIVATE_KEY) \
		--broadcast \
		-vvv

# Sign Credential on Anvil
sign-credential-anvil:
	@echo "Signing credential on Anvil..."
	forge script script/interactions/Interactions.s.sol:SignCredentialInteraction \
		--rpc-url $(ANVIL_RPC_URL) \
		--broadcast \
		-vvv

# Sign Credential on Sepolia
sign-credential-sepolia:
	@echo "Signing credential on Sepolia..."
	forge script script/interactions/Interactions.s.sol:SignCredentialInteraction \
		--rpc-url $(SEPOLIA_RPC_URL) \
		--private-key $(PRIVATE_KEY) \
		--broadcast \
		-vvv

# Verify Credential (view function - no broadcast needed)
verify-credential-anvil:
	@echo "Verifying credential on Anvil..."
	forge script script/interactions/Interactions.s.sol:VerifyCredentialInteraction \
		--rpc-url $(ANVIL_RPC_URL) \
		-vvv

# Verify Credential on Sepolia
verify-credential-sepolia:
	@echo "Verifying credential on Sepolia..."
	forge script script/interactions/Interactions.s.sol:VerifyCredentialInteraction \
		--rpc-url $(SEPOLIA_RPC_URL) \
		-vvv

# Get Student Credentials
student-credentials-anvil:
	@echo "Getting student credentials on Anvil..."
	forge script script/interactions/Interactions.s.sol:GetStudentCredentialsInteraction \
		--rpc-url $(ANVIL_RPC_URL) \
		-vvv

# Get Student Credentials on Sepolia
student-credentials-sepolia:
	@echo "Getting student credentials on Sepolia..."
	forge script script/interactions/Interactions.s.sol:GetStudentCredentialsInteraction \
		--rpc-url $(SEPOLIA_RPC_URL) \
		-vvv

# Revoke Credential on Anvil
revoke-credential-anvil:
	@echo "Revoking credential on Anvil..."
	forge script script/interactions/Interactions.s.sol:RevokeCredentialInteraction \
		--rpc-url $(ANVIL_RPC_URL) \
		--broadcast \
		-vvv

# Revoke Credential on Sepolia
revoke-credential-sepolia:
	@echo "Revoking credential on Sepolia..."
	forge script script/interactions/Interactions.s.sol:RevokeCredentialInteraction \
		--rpc-url $(SEPOLIA_RPC_URL) \
		--private-key $(PRIVATE_KEY) \
		--broadcast \
		-vvv

# ================================================================
# UTILITIES
# ================================================================

# Flatten contracts for verification
flatten:
	forge flatten src/AcademicCredential.sol -o flattened/AcademicCredential.sol
	forge flatten src/UniversityRegistry.sol -o flattened/UniversityRegistry.sol
	forge flatten src/CredentialVerifier.sol -o flattened/CredentialVerifier.sol

# Estimate gas for deployment
gas-estimate:
	forge script script/DeploySystem.s.sol:DeploySystem --rpc-url $(SEPOLIA_RPC_URL) --estimate-gas

# Lint contracts
lint:
	forge fmt --check

# Inspect contract storage layout
inspect-storage:
	forge inspect AcademicCredential storage-layout
	forge inspect UniversityRegistry storage-layout
	forge inspect CredentialVerifier storage-layout

# Check contract sizes
contract-size:
	forge build --sizes

# Security checks with slither (requires slither installation)
slither:
	slither .

# ================================================================
# ADVANCED
# ================================================================

# Run tests with coverage and gas report
test-advanced:
	forge test -vvv --gas-report --coverage

# Test specific contract
test-contract:
	@read -p "Enter contract name (e.g., AcademicCredentialTest): " contract; \
	forge test --match-contract $$contract -vvv

# Test specific function
test-function:
	@read -p "Enter test function name: " func; \
	forge test --match-test $$func -vvvv

# Fork test Sepolia
fork-test-sepolia:
	forge test --fork-url $(SEPOLIA_RPC_URL) -vvv

# Create and fund test accounts on Anvil
setup-test-accounts:
	@echo "Setting up test accounts on Anvil..."
	cast send $(TEST_ACCOUNT_1) --value 10ether --private-key $(ANVIL_PRIVATE_KEY) --rpc-url $(ANVIL_RPC_URL)
	cast send $(TEST_ACCOUNT_2) --value 10ether --private-key $(ANVIL_PRIVATE_KEY) --rpc-url $(ANVIL_RPC_URL)
	@echo "Test accounts funded!"

# Check deployment addresses
check-deployments:
	@echo "Checking deployment addresses..."
	@if [ -d "broadcast/DeploySystem.s.sol" ]; then \
		echo "Recent deployments:"; \
		find broadcast/DeploySystem.s.sol -name "*.json" -type f -exec echo {} \;; \
	else \
		echo "No deployments found"; \
	fi
