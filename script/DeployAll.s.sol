// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {UniversityRegistry} from "../src/UniversityRegistry.sol";
import {AcademicCredential} from "../src/AcademicCredential.sol";
import {CredentialVerifier} from "../src/CredentialVerifier.sol";

/**
 * @title DeployAll
 * @notice Deployment script for all contracts in the Academic Credentials system
 * @dev Run with: forge script script/DeployAll.s.sol:DeployAll --rpc-url <RPC_URL> --broadcast
 */
contract DeployAll is Script {
    UniversityRegistry public registry;
    AcademicCredential public credential;
    CredentialVerifier public verifier;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying contracts with address:", deployer);
        console.log("Deployer balance:", deployer.balance);

        vm.startBroadcast(deployerPrivateKey);

        // Step 1: Deploy UniversityRegistry
        console.log("\n1. Deploying UniversityRegistry...");
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
        console.log("DEPLOYMENT SUMMARY");
        console.log("========================================");
        console.log("UniversityRegistry:    ", address(registry));
        console.log("AcademicCredential:    ", address(credential));
        console.log("CredentialVerifier:    ", address(verifier));
        console.log("========================================");
        console.log("\nSave these addresses for future interactions!");
    }
}
