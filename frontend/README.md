# Academic Proof Frontend

A clean, modern React frontend for the Academic Proof decentralized academic credentials system. This application allows students to view their credentials, universities to issue credentials, and verifiers to authenticate academic credentials on the blockchain.

## Features

- **Student Dashboard**: View all academic credentials stored as Soulbound NFTs
- **University Dashboard**: Issue new credentials with multi-signature approval
- **Verifier Dashboard**: Instantly verify credential authenticity
- **Wallet Integration**: MetaMask connection for Sepolia testnet
- **Real-time Updates**: Automatic contract interaction and state management

## Tech Stack

- **React 18** with TypeScript
- **Vite** for fast development and building
- **TailwindCSS** for modern, responsive styling
- **ethers.js v6** for blockchain interaction
- **React Router** for navigation

## Prerequisites

- Node.js 16+ and npm
- MetaMask browser extension
- Sepolia testnet ETH (get from faucets)

## Installation

```bash
# Navigate to frontend directory
cd frontend

# Install dependencies
npm install

# Start development server
npm run dev
```

The application will be available at `http://localhost:5173`

## Usage

### 1. Connect Wallet
Click "Connect Wallet" to connect your MetaMask wallet to Sepolia testnet.

### 2. Student Dashboard (`/student`)
View all your academic credentials issued to your wallet address.

### 3. University Dashboard (`/university`)
Issue new credentials (requires authorized signer status).

### 4. Verifier Dashboard (`/verifier`)
Verify credential authenticity by entering a credential ID.

## Smart Contract Addresses (Sepolia)

- **UniversityRegistry**: `0x777cc9de0180ab4A98072C86cb67c7763906D6B1`
- **AcademicCredential**: `0x73F397Eb0eE3d849aa14fCa1Ecb4d0016f24C475`
- **CredentialVerifier**: `0x98F3773D5fdc03a5821826C65e85E239bc5bEAaB`

## Building for Production

```bash
npm run build
```

The output will be in the `dist/` directory.

## License

MIT License
