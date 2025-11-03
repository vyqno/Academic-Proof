// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {UniversityRegistry} from "../src/UniversityRegistry.sol";
import {AcademicCredential} from "../src/AcademicCredential.sol";
import {CredentialVerifier} from "../src/CredentialVerifier.sol";

/**
 * @title HelperConfig
 * @notice Configuration helper for multi-network deployment
 * @dev Manages network-specific configurations and mock deployments
 */
contract HelperConfig is Script {
    struct NetworkConfig {
        address universityRegistry;
        address academicCredential;
        address credentialVerifier;
        address deployer;
    }

    NetworkConfig public activeNetworkConfig;

    uint256 public constant DEFAULT_ANVIL_PRIVATE_KEY =
        0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaConfig();
        } else if (block.chainid == 1) {
            activeNetworkConfig = getMainnetConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilConfig();
        }
    }

    function getSepoliaConfig() public view returns (NetworkConfig memory) {
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            universityRegistry: address(0), // Will be deployed
            academicCredential: address(0), // Will be deployed
            credentialVerifier: address(0), // Will be deployed
            deployer: msg.sender
        });

        return sepoliaConfig;
    }

    function getMainnetConfig() public view returns (NetworkConfig memory) {
        NetworkConfig memory mainnetConfig = NetworkConfig({
            universityRegistry: address(0), // Configure after deployment
            academicCredential: address(0), // Configure after deployment
            credentialVerifier: address(0), // Configure after deployment
            deployer: msg.sender
        });

        return mainnetConfig;
    }

    function getOrCreateAnvilConfig() public returns (NetworkConfig memory) {
        // Check if already deployed
        if (activeNetworkConfig.universityRegistry != address(0)) {
            return activeNetworkConfig;
        }

        console.log("Deploying mocks and contracts to Anvil...");

        vm.startBroadcast(DEFAULT_ANVIL_PRIVATE_KEY);

        // Deploy contracts
        UniversityRegistry registry = new UniversityRegistry();
        AcademicCredential credential = new AcademicCredential(address(registry));
        CredentialVerifier verifier = new CredentialVerifier(address(credential), address(registry));

        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig({
            universityRegistry: address(registry),
            academicCredential: address(credential),
            credentialVerifier: address(verifier),
            deployer: vm.addr(DEFAULT_ANVIL_PRIVATE_KEY)
        });

        return anvilConfig;
    }

    function getConfig() external view returns (NetworkConfig memory) {
        return activeNetworkConfig;
    }

    function getConfigByChainId(uint256 chainId) external returns (NetworkConfig memory) {
        if (chainId == 11155111) {
            return getSepoliaConfig();
        } else if (chainId == 1) {
            return getMainnetConfig();
        } else {
            return getOrCreateAnvilConfig();
        }
    }
}
