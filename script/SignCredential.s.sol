// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {AcademicCredential} from "../src/AcademicCredential.sol";

/**
 * @title SignCredential
 * @notice Script for signing a credential request
 * @dev Run with: forge script script/SignCredential.s.sol:SignCredential --rpc-url <RPC_URL> --broadcast
 *
 * Environment variables required:
 * - PRIVATE_KEY: Authorized signer private key
 * - CREDENTIAL_ADDRESS: Address of deployed AcademicCredential
 * - CREDENTIAL_ID: ID of credential to sign
 */
contract SignCredential is Script {
    function run() external {
        uint256 signerPrivateKey = vm.envUint("PRIVATE_KEY");
        address credentialAddress = vm.envAddress("CREDENTIAL_ADDRESS");
        uint256 credentialId = vm.envUint("CREDENTIAL_ID");

        console.log("Signing credential...");
        console.log("Credential contract:", credentialAddress);
        console.log("Credential ID:", credentialId);

        AcademicCredential credential = AcademicCredential(credentialAddress);

        // Check approval status before signing
        (uint256 sigCount, uint256 required, bool issued) = credential.getApprovalStatus(credentialId);

        console.log("\nBefore signing:");
        console.log("  Signatures:", sigCount);
        console.log("  Required:", required);
        console.log("  Issued:", issued);

        vm.startBroadcast(signerPrivateKey);

        credential.signCredential(credentialId);

        vm.stopBroadcast();

        // Check approval status after signing
        (sigCount, required, issued) = credential.getApprovalStatus(credentialId);

        console.log("\nAfter signing:");
        console.log("  Signatures:", sigCount);
        console.log("  Required:", required);
        console.log("  Issued:", issued);

        console.log("\n========================================");
        if (issued) {
            console.log("CREDENTIAL ISSUED SUCCESSFULLY");
            console.log("The credential has been minted to the student");
        } else {
            console.log("SIGNATURE ADDED");
            console.log("Additional signatures required:", required - sigCount);
        }
        console.log("========================================");
    }
}
