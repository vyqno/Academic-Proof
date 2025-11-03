// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {CredentialVerifier} from "../src/CredentialVerifier.sol";
import {CredentialMetadata} from "../src/libraries/CredentialMetadata.sol";

/**
 * @title VerifyCredential
 * @notice Script for verifying academic credentials
 * @dev Run with: forge script script/VerifyCredential.s.sol:VerifyCredential --rpc-url <RPC_URL>
 *
 * Environment variables required:
 * - VERIFIER_ADDRESS: Address of deployed CredentialVerifier
 * - CREDENTIAL_ID: ID of credential to verify
 */
contract VerifyCredential is Script {
    function run() external view {
        address verifierAddress = vm.envAddress("VERIFIER_ADDRESS");
        uint256 credentialId = vm.envUint("CREDENTIAL_ID");

        console.log("Verifying credential...");
        console.log("Verifier contract:", verifierAddress);
        console.log("Credential ID:", credentialId);
        console.log("");

        CredentialVerifier verifier = CredentialVerifier(verifierAddress);

        // Get verification result
        CredentialVerifier.VerificationResult memory result = verifier.getCredentialDetails(credentialId);

        console.log("========================================");
        console.log("CREDENTIAL VERIFICATION RESULT");
        console.log("========================================");

        if (!result.exists) {
            console.log("Status: CREDENTIAL DOES NOT EXIST");
            console.log("========================================");
            return;
        }

        console.log("Exists:", result.exists);
        console.log("Issued:", result.isIssued);
        console.log("Revoked:", result.isRevoked);
        console.log("Valid:", result.isValid);
        console.log("");

        if (result.isValid) {
            console.log("--- CREDENTIAL DETAILS ---");
            console.log("Student:", result.student);
            console.log("University:", result.universityName);
            console.log("University ID:", result.universityId);
            console.log("Degree:", CredentialMetadata.degreeTypeToString(result.degreeType));
            console.log("Major:", result.major);

            // Display GPA
            uint256 gpaWhole = result.gpa / 100;
            uint256 gpaDecimal = result.gpa % 100;
            console.log("GPA:", gpaWhole);
            console.log("GPA Decimal:", gpaDecimal);

            console.log("Honors:", CredentialMetadata.honorsToString(result.honors));
            console.log("Graduation Date:", result.graduationDate);
            console.log("");

            // Get verification summary
            string memory summary = verifier.getVerificationSummary(credentialId);
            console.log("Summary:", summary);
        } else if (!result.isIssued) {
            console.log("Status: PENDING APPROVAL");
            console.log("Student:", result.student);
            console.log("Major:", result.major);
        } else if (result.isRevoked) {
            console.log("Status: REVOKED");
            console.log("Student:", result.student);
            console.log("University:", result.universityName);
            console.log("Major:", result.major);
        }

        console.log("========================================");
    }
}
