import React, { createContext, useContext, useState, useEffect } from 'react';
import type { ReactNode } from 'react';
import { BrowserProvider, Contract } from 'ethers';
import type { Eip1193Provider } from 'ethers';
import { CONTRACTS, SEPOLIA_CHAIN_ID, NETWORK_CONFIG } from '../contracts/config';
import AcademicCredentialABI from '../contracts/AcademicCredential.json';
import UniversityRegistryABI from '../contracts/UniversityRegistry.json';
import CredentialVerifierABI from '../contracts/CredentialVerifier.json';

declare global {
  interface Window {
    ethereum?: Eip1193Provider & {
      request: (request: { method: string; params?: Array<unknown> }) => Promise<unknown>;
      on?: (event: string, callback: (...args: unknown[]) => void) => void;
      removeListener?: (event: string, callback: (...args: unknown[]) => void) => void;
    };
  }
}

interface WalletContextType {
  account: string | null;
  provider: BrowserProvider | null;
  academicCredentialContract: Contract | null;
  universityRegistryContract: Contract | null;
  credentialVerifierContract: Contract | null;
  isConnecting: boolean;
  error: string | null;
  connectWallet: () => Promise<void>;
  disconnectWallet: () => void;
}

const WalletContext = createContext<WalletContextType | undefined>(undefined);

export const WalletProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const [account, setAccount] = useState<string | null>(null);
  const [provider, setProvider] = useState<BrowserProvider | null>(null);
  const [academicCredentialContract, setAcademicCredentialContract] = useState<Contract | null>(null);
  const [universityRegistryContract, setUniversityRegistryContract] = useState<Contract | null>(null);
  const [credentialVerifierContract, setCredentialVerifierContract] = useState<Contract | null>(null);
  const [isConnecting, setIsConnecting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const initializeContracts = async (signer: BrowserProvider) => {
    const signerInstance = await signer.getSigner();

    const academicCredential = new Contract(
      CONTRACTS.AcademicCredential,
      AcademicCredentialABI,
      signerInstance
    );

    const universityRegistry = new Contract(
      CONTRACTS.UniversityRegistry,
      UniversityRegistryABI,
      signerInstance
    );

    const credentialVerifier = new Contract(
      CONTRACTS.CredentialVerifier,
      CredentialVerifierABI,
      signerInstance
    );

    setAcademicCredentialContract(academicCredential);
    setUniversityRegistryContract(universityRegistry);
    setCredentialVerifierContract(credentialVerifier);
  };

  const connectWallet = async () => {
    setIsConnecting(true);
    setError(null);

    try {
      if (!window.ethereum) {
        throw new Error('MetaMask is not installed. Please install MetaMask to use this app.');
      }

      const accounts = await window.ethereum.request({
        method: 'eth_requestAccounts',
      }) as string[];

      if (accounts.length === 0) {
        throw new Error('No accounts found');
      }

      const browserProvider = new BrowserProvider(window.ethereum);
      const network = await browserProvider.getNetwork();

      if (Number(network.chainId) !== SEPOLIA_CHAIN_ID) {
        try {
          await window.ethereum.request({
            method: 'wallet_switchEthereumChain',
            params: [{ chainId: NETWORK_CONFIG.chainId }],
          });
        } catch (switchError: unknown) {
          if ((switchError as { code: number }).code === 4902) {
            await window.ethereum.request({
              method: 'wallet_addEthereumChain',
              params: [NETWORK_CONFIG],
            });
          } else {
            throw switchError;
          }
        }
      }

      setAccount(accounts[0]);
      setProvider(browserProvider);
      await initializeContracts(browserProvider);
    } catch (err) {
      setError((err as Error).message);
      console.error('Error connecting wallet:', err);
    } finally {
      setIsConnecting(false);
    }
  };

  const disconnectWallet = () => {
    setAccount(null);
    setProvider(null);
    setAcademicCredentialContract(null);
    setUniversityRegistryContract(null);
    setCredentialVerifierContract(null);
  };

  useEffect(() => {
    if (window.ethereum?.on) {
      const handleAccountsChanged = (accounts: unknown) => {
        const accountArray = accounts as string[];
        if (accountArray.length === 0) {
          disconnectWallet();
        } else {
          setAccount(accountArray[0]);
        }
      };

      const handleChainChanged = () => {
        window.location.reload();
      };

      window.ethereum.on('accountsChanged', handleAccountsChanged);
      window.ethereum.on('chainChanged', handleChainChanged);

      return () => {
        if (window.ethereum?.removeListener) {
          window.ethereum.removeListener('accountsChanged', handleAccountsChanged);
          window.ethereum.removeListener('chainChanged', handleChainChanged);
        }
      };
    }
  }, []);

  const value: WalletContextType = {
    account,
    provider,
    academicCredentialContract,
    universityRegistryContract,
    credentialVerifierContract,
    isConnecting,
    error,
    connectWallet,
    disconnectWallet,
  };

  return <WalletContext.Provider value={value}>{children}</WalletContext.Provider>;
};

export const useWallet = () => {
  const context = useContext(WalletContext);
  if (context === undefined) {
    throw new Error('useWallet must be used within a WalletProvider');
  }
  return context;
};
