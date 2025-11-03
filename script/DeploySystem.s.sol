// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {UniversityRegistry} from "../src/UniversityRegistry.sol";
import {AcademicCredential} from "../src/AcademicCredential.sol";
import {CredentialVerifier} from "../src/CredentialVerifier.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

/**
 * @title DeploySystem
 * @notice Main deployment script using HelperConfig for multi-network support
 * @dev Run with: forge script script/DeploySystem.s.sol:DeploySystem --rpc-url <RPC_URL> --broadcast
 */
contract DeploySystem is Script {
    function run()
        external
        returns (UniversityRegistry registry, AcademicCredential credential, CredentialVerifier verifier)
    {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        uint256 deployerPrivateKey;

        // Use environment variable or default for anvil
        if (block.chainid == 31337) {
            deployerPrivateKey = helperConfig.DEFAULT_ANVIL_PRIVATE_KEY();
        } else {
            deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        }

        address deployer = vm.addr(deployerPrivateKey);

        console.log("========================================");
        console.log("DEPLOYING TO:", getChainName());
        console.log("Chain ID:", block.chainid);
        console.log("Deployer:", deployer);
        console.log("Deployer balance:", deployer.balance);
        console.log("========================================\n");

        vm.startBroadcast(deployerPrivateKey);

        // Step 1: Deploy UniversityRegistry
        console.log("1. Deploying UniversityRegistry...");
        registry = new UniversityRegistry();
        console.log("   UniversityRegistry deployed at:", address(registry));

        // Step 2: Deploy AcademicCredential
        console.log("\n2. Deploying AcademicCredential...");
        credential = new AcademicCredential(address(registry));
        console.log("   AcademicCredential deployed at:", address(credential));

        // Step 3: Deploy CredentialVerifier
        console.log("\n3. Deploying CredentialVerifier...");
        verifier = new CredentialVerifier(address(credential), address(registry));
        console.log("   CredentialVerifier deployed at:", address(verifier));

        vm.stopBroadcast();

        // Print deployment summary
        console.log("\n========================================");
        console.log("DEPLOYMENT COMPLETE");
        console.log("========================================");
        console.log("Network:", getChainName());
        console.log("UniversityRegistry:    ", address(registry));
        console.log("AcademicCredential:    ", address(credential));
        console.log("CredentialVerifier:    ", address(verifier));
        console.log("========================================");

        return (registry, credential, verifier);
    }

    function getChainName() internal view returns (string memory) {
        if (block.chainid == 1) return "Ethereum Mainnet";
        if (block.chainid == 11155111) return "Sepolia Testnet";
        if (block.chainid == 31337) return "Anvil Local";
        return "Unknown Network";
    }
}
