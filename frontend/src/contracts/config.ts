// Contract addresses on Sepolia testnet
export const CONTRACTS = {
  UniversityRegistry: "0x777cc9de0180ab4A98072C86cb67c7763906D6B1",
  AcademicCredential: "0x73F397Eb0eE3d849aa14fCa1Ecb4d0016f24C475",
  CredentialVerifier: "0x98F3773D5fdc03a5821826C65e85E239bc5bEAaB",
} as const;

export const SEPOLIA_CHAIN_ID = 11155111;
export const SEPOLIA_RPC_URL = "https://rpc.sepolia.org";

export const NETWORK_CONFIG = {
  chainId: `0x${SEPOLIA_CHAIN_ID.toString(16)}`,
  chainName: "Sepolia Testnet",
  nativeCurrency: {
    name: "Sepolia ETH",
    symbol: "ETH",
    decimals: 18,
  },
  rpcUrls: [SEPOLIA_RPC_URL],
  blockExplorerUrls: ["https://sepolia.etherscan.io"],
};
